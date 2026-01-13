import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Button } from '../atoms/Button';
import { Input } from '../atoms/Input';
import { Icons } from '../atoms/Icon';

interface MemberModalProps {
  onClose: () => void;
  onSuccess: () => void;
  initialData?: any; // If provided, we are in Edit mode
}

export const MemberModal: React.FC<MemberModalProps> = ({ onClose, onSuccess, initialData }) => {
  const [member, setMember] = useState<{name: string, email: string, password: string, file: File | null, packageId: string}>({ 
    name: '', email: '', password: '', file: null, packageId: '' 
  });
  const [loading, setLoading] = useState(false);
  const [packages, setPackages] = useState<any[]>([]);

  // Fetch packages on mount
  useEffect(() => {
    const fetchPackages = async () => {
      try {
        const res = await axios.get('http://localhost:8080/api/management/packages');
        setPackages(res.data.data);
      } catch (e) {
        console.error('Failed to fetch packages', e);
      }
    };
    fetchPackages();
  }, []);

  // Initialize form if editing
  useEffect(() => {
    if (initialData) {
      setMember({
        name: initialData.name,
        email: initialData.email,
        password: '', // Leave empty to keep unchanged
        file: null,
        packageId: initialData.package?.id ? String(initialData.package.id) : ''
      });
    }
  }, [initialData]);

  // Calculate End Date based on selection
  const getEndDate = () => {
    if (!member.packageId) return '';
    const pkg = packages.find(p => p.id === Number(member.packageId));
    if (!pkg) return '';
    const date = new Date();
    date.setDate(date.getDate() + pkg.duration_days);
    return date.toLocaleDateString();
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (initialData) {
        // Edit Mode
        await axios.put(`http://localhost:8080/api/admin/members/${initialData.id}`, {
          name: member.name, 
          email: member.email,
          package_id: member.packageId ? Number(member.packageId) : null
        });
        
        // If package changed, we might need a separate call or handle it in backend. 
        // For now, assuming basic edit. If we want to change sub, we usually use the Subscribe action in table.
      } else {
        // Create Mode
        const formData = new FormData();
        formData.append('name', member.name);
        formData.append('email', member.email);
        formData.append('password', member.password);
        if (member.packageId) formData.append('package_id', member.packageId);
        if (member.file) formData.append('profile_picture', member.file);

        await axios.post('http://localhost:8080/api/auth/register', formData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        });
      }
      onSuccess();
      onClose();
    } catch (error) {
      alert(`Failed to ${initialData ? 'update' : 'create'} member.`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div className="bg-slate-900 border border-white/10 rounded-2xl p-6 w-full max-w-md shadow-2xl">
        <h3 className="text-xl font-bold text-white mb-4">{initialData ? 'Edit Member' : 'Add New Member'}</h3>
        <form onSubmit={handleSubmit} className="space-y-4">
          {!initialData && (
            <div className="flex justify-center mb-4">
               <div className="relative w-24 h-24 rounded-full bg-slate-800 border border-dashed border-slate-600 flex items-center justify-center overflow-hidden hover:border-gym-brand transition-colors cursor-pointer group">
                  {member.file ? (
                      <img src={URL.createObjectURL(member.file)} alt="Preview" className="w-full h-full object-cover" />
                  ) : (
                      <div className="text-center group-hover:text-gym-brand transition-colors text-slate-400">
                          <Icons.Users />
                          <span className="text-[10px] block mt-1">Upload</span>
                      </div>
                  )}
                  <input type="file" accept="image/*" className="absolute inset-0 opacity-0 cursor-pointer"
                      onChange={e => { if (e.target.files && e.target.files[0]) setMember({...member, file: e.target.files[0]}); }}
                  />
               </div>
            </div>
          )}

          <Input label="Full Name" placeholder="John Doe" required value={member.name}
            onChange={e => setMember({...member, name: e.target.value})}
          />
          
          <Input label="Email Address" type="email" placeholder="john@example.com" required value={member.email}
            onChange={e => setMember({...member, email: e.target.value})}
          />

          {!initialData && (
             <Input label="Default Password" type="password" placeholder="••••••••" required value={member.password}
               onChange={e => setMember({...member, password: e.target.value})}
             />
          )}

           <div className="grid grid-cols-2 gap-4">
             <div>
               <label className="block text-sm font-medium text-slate-400 mb-1">Select Plan</label>
               <select className="w-full px-4 py-3 rounded-xl bg-slate-800 border-2 border-slate-700 text-white focus:outline-none focus:ring-2 focus:ring-gym-brand/50"
                 value={member.packageId} onChange={e => setMember({...member, packageId: e.target.value})}
               >
                 <option value="">No Plan</option>
                 {packages.map(p => <option key={p.id} value={p.id}>{p.name} (${p.price})</option>)}
               </select>
             </div>
             {/* Show end date only if package selected. In Edit mode, this calculation is simulated based on NEW package. */}
             <div>
                <label className="block text-sm font-medium text-slate-400 mb-1">{initialData ? 'New End Date (Est.)' : 'Ends On'}</label>
                <div className="w-full px-4 py-3 rounded-xl bg-slate-800/50 border border-slate-700 text-slate-400">{getEndDate() || '-'}</div>
             </div>
           </div>

          <div className="flex gap-3 mt-6">
            <Button type="submit" fullWidth disabled={loading}>
              {loading ? 'Processing...' : (initialData ? 'Update Member' : 'Create Member')}
            </Button>
            <Button type="button" variant="secondary" fullWidth onClick={onClose}>Cancel</Button>
          </div>
        </form>
      </div>
    </div>
  );
};
