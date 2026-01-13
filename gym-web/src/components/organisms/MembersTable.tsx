import React, { useState } from 'react';
import { Card } from '../atoms/Card';
import { Icons } from '../atoms/Icon';
import axios from 'axios';
import { API_URL } from '../../config';

interface Member {
  id: number;
  name: string;
  email: string;
  membership_status: string;
  sub_end_date?: string;
  profile_picture?: string;
  package?: { name: string; price: number };
}

interface MembersTableProps {
  members: Member[];
  packages: any[];
  onUpdate: () => void;
  onEdit: (member: Member) => void;
}

export const MembersTable: React.FC<MembersTableProps> = ({ members, packages, onUpdate, onEdit }) => {
  const [selectedMember, setSelectedMember] = useState<number | null>(null);
  const [selectedPackage, setSelectedPackage] = useState<number | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [viewImage, setViewImage] = useState<string | null>(null);

  const filteredMembers = members.filter(m => {
    const matchesSearch = m.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
                          m.email.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || m.membership_status === filterStatus;
    return matchesSearch && matchesStatus;
  });

  const handleSubscribe = async () => {
    if (!selectedMember || !selectedPackage) return;
    try {
      await axios.post(`${API_URL}/admin/members/subscribe`, {
        member_id: selectedMember, package_id: selectedPackage
      });
      setSelectedMember(null);
      onUpdate();
    } catch (e) { alert('Error updating subscription'); }
  };

  const handleDelete = async (id: number) => {
    if (window.confirm('Are you sure you want to delete this member?')) {
      try {
        await axios.delete(`${API_URL}/admin/members/${id}`);
        onUpdate();
      } catch (e) { alert('Failed to delete member'); }
    }
  };

  return (
    <>
      {/* Lightbox Modal */}
      {viewImage && (
        <div 
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/90 backdrop-blur-sm p-4 cursor-zoom-out"
          onClick={() => setViewImage(null)}
        >
           <img 
             src={viewImage} 
             alt="Full size" 
             className="max-w-full max-h-[90vh] rounded-xl shadow-2xl object-contain animate-in fade-in zoom-in duration-200"
           />
           <button className="absolute top-4 right-4 text-white hover:text-red-400">
             <Icons.Trash className="w-8 h-8 rotate-45" /> {/* Using Trash as Close icon X if no other X icon */}
           </button>
        </div>
      )}

      <Card>
        <div className="p-4 border-b border-slate-700 flex flex-col sm:flex-row gap-4 justify-between items-center">
          {/* ... existing header code ... */}
          <div className="relative w-full sm:w-64">
             <Icons.Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
             <input 
               className="w-full bg-slate-900 border border-slate-700 rounded-lg py-2 pl-10 pr-4 text-white text-sm focus:outline-none focus:border-gym-brand"
               placeholder="Search members..."
               value={searchTerm}
               onChange={e => setSearchTerm(e.target.value)}
             />
          </div>
          <select 
            className="bg-slate-900 border border-slate-700 rounded-lg px-4 py-2 text-white text-sm focus:outline-none focus:border-gym-brand"
            value={filterStatus}
            onChange={e => setFilterStatus(e.target.value)}
          >
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-700 text-slate-400 text-sm uppercase">
                <th className="p-4 w-16"></th>
                <th className="p-4">Name</th>
                <th className="p-4">Status</th>
                <th className="p-4">Current Plan</th>
                <th className="p-4">Sub End Date</th>
                <th className="p-4">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800">
              {filteredMembers.map(m => (
                <tr key={m.id} className="hover:bg-slate-800/30 transition-colors">
                  <td className="p-4">
                     <div 
                        className="w-10 h-10 rounded-full bg-slate-800 overflow-hidden ring-1 ring-white/10 cursor-pointer hover:ring-2 hover:ring-gym-brand transition-all"
                        onClick={() => m.profile_picture && setViewImage(`${API_URL}${m.profile_picture}`)}
                     >
                        {m.profile_picture ? (
                            <img 
                                src={`${API_URL}${m.profile_picture}`} 
                                alt={m.name} 
                                className="w-full h-full object-cover" 
                            />
                        ) : (
                            <div className="w-full h-full flex items-center justify-center text-slate-500">
                                <span className="text-xs font-bold">{m.name.charAt(0)}</span>
                            </div>
                        )}
                     </div>
                  </td>
                  <td className="p-4">
                    <div className="font-medium text-white">{m.name}</div>
                    <div className="text-sm text-slate-500">{m.email}</div>
                  </td>
                  <td className="p-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                      m.membership_status === 'active' ? 'bg-green-500/10 text-green-400' : 'bg-red-500/10 text-red-400'
                    }`}>
                      {m.membership_status ? m.membership_status.toUpperCase() : 'UNKNOWN'}
                    </span>
                  </td>
                  <td className="p-4 text-slate-300">{m.package?.name || '-'}</td>
                  <td className="p-4 text-slate-400">{m.sub_end_date ? new Date(m.sub_end_date).toLocaleDateString() : '-'}</td>
                  <td className="p-4">
                    {selectedMember === m.id ? (
                      <div className="flex gap-2 items-center">
                        <select 
                          className="bg-slate-900 border border-slate-700 rounded px-2 py-1 text-sm text-white focus:outline-none focus:ring-1 focus:ring-gym-brand"
                          onChange={e => setSelectedPackage(Number(e.target.value))}
                        >
                          <option value="">Select Plan...</option>
                          {packages.map(p => <option key={p.id} value={p.id}>{p.name} (${p.price})</option>)}
                        </select>
                        <button onClick={handleSubscribe} className="text-gym-brand hover:text-gym-400 text-sm font-bold">Save</button>
                        <button onClick={() => setSelectedMember(null)} className="text-slate-500 hover:text-slate-400 text-sm">Cancel</button>
                      </div>
                    ) : (
                      <div className="flex gap-3">
                         <button onClick={() => onEdit(m)} className="text-slate-400 hover:text-white transition-colors">
                            <Icons.Edit className="w-4 h-4" />
                         </button>
                         <button onClick={() => setSelectedMember(m.id)} className="text-blue-400 hover:text-blue-300 transition-colors text-sm font-bold">
                            Sub
                         </button>
                         <button onClick={() => handleDelete(m.id)} className="text-red-400 hover:text-red-300 transition-colors">
                            <Icons.Trash className="w-4 h-4" />
                         </button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </>
  );
};
