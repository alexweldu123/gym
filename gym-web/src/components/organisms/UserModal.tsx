import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Button } from '../atoms/Button';
import { Input } from '../atoms/Input';
import { API_URL } from '../../config';

interface UserModalProps {
  onClose: () => void;
  onSuccess: () => void;
  initialData?: any;
}

export const UserModal: React.FC<UserModalProps> = ({ onClose, onSuccess, initialData }) => {
  const [user, setUser] = useState<{name: string, email: string, password: string, role: string}>({ 
    name: '', email: '', password: '', role: 'staff' 
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (initialData) {
      setUser({
        name: initialData.name,
        email: initialData.email,
        password: '',
        role: initialData.role
      });
    }
  }, [initialData]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (initialData) {
        await axios.put(`${API_URL}/admin/users/${initialData.id}`, {
          name: user.name, 
          email: user.email,
          role: user.role
        });
      } else {
        await axios.post(`${API_URL}/admin/users`, user);
      }
      onSuccess();
      onClose();
    } catch (error) {
      alert(`Failed to ${initialData ? 'update' : 'create'} user.`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div className="bg-slate-900 border border-white/10 rounded-2xl p-6 w-full max-w-md shadow-2xl">
        <h3 className="text-xl font-bold text-white mb-4">{initialData ? 'Edit User' : 'Add New User'}</h3>
        <form onSubmit={handleSubmit} className="space-y-4">

          <Input label="Full Name" placeholder="Jane Doe" required value={user.name}
            onChange={e => setUser({...user, name: e.target.value})}
          />
          
          <Input label="Email Address" type="email" placeholder="jane@gym.com" required value={user.email}
            onChange={e => setUser({...user, email: e.target.value})}
          />

          {!initialData && (
             <Input label="Default Password" type="password" placeholder="••••••••" required value={user.password}
               onChange={e => setUser({...user, password: e.target.value})}
             />
          )}

          <div>
            <label className="block text-sm font-medium text-slate-400 mb-1">Role</label>
            <select className="w-full px-4 py-3 rounded-xl bg-slate-800 border-2 border-slate-700 text-white focus:outline-none focus:ring-2 focus:ring-gym-brand/50"
              value={user.role} onChange={e => setUser({...user, role: e.target.value})}
            >
              <option value="staff">Staff</option>
              <option value="trainer">Trainer</option>
            </select>
          </div>

          <div className="flex gap-3 mt-6">
            <Button type="submit" fullWidth disabled={loading}>
              {loading ? 'Processing...' : (initialData ? 'Update' : 'Create')}
            </Button>
            <Button type="button" variant="secondary" fullWidth onClick={onClose}>Cancel</Button>
          </div>
        </form>
      </div>
    </div>
  );
};
