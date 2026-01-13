import React from 'react';
import { Card } from '../atoms/Card';
import { Icons } from '../atoms/Icon';
import axios from 'axios';

interface UsersTableProps {
  users: any[];
  onUpdate: () => void;
  onEdit: (user: any) => void;
}

export const UsersTable: React.FC<UsersTableProps> = ({ users, onUpdate, onEdit }) => {

  const handleToggleStatus = async (user: any) => {
    try {
      await axios.post(`http://localhost:8080/api/admin/users/${user.id}/toggle`);
      onUpdate();
    } catch(e) { alert('Failed to toggle status'); }
  };

  const handleDelete = async (id: number) => {
    if (window.confirm('Are you sure you want to delete this user?')) {
      try {
        await axios.delete(`http://localhost:8080/api/admin/users/${id}`);
        onUpdate();
      } catch (e) { alert('Failed to delete user'); }
    }
  };

  return (
    <Card>
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b border-slate-700 text-slate-400 text-sm uppercase">
              <th className="p-4">Name</th>
              <th className="p-4">Role</th>
              <th className="p-4">Status</th>
              <th className="p-4">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {users.map(u => (
              <tr key={u.id} className="hover:bg-slate-800/30 transition-colors">
                <td className="p-4">
                  <div className="font-medium text-white">{u.name}</div>
                  <div className="text-sm text-slate-500">{u.email}</div>
                </td>
                <td className="p-4">
                  <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                    u.role === 'staff' ? 'bg-purple-500/10 text-purple-400' : 'bg-orange-500/10 text-orange-400'
                  }`}>
                    {u.role.toUpperCase()}
                  </span>
                </td>
                <td className="p-4">
                  <button 
                    onClick={() => handleToggleStatus(u)}
                    className={`px-3 py-1 rounded-full text-xs font-semibold border transition-all ${
                      u.is_active 
                      ? 'bg-green-500/10 text-green-400 border-green-500/20 hover:bg-red-500/10 hover:text-red-400 hover:border-red-500/20' 
                      : 'bg-red-500/10 text-red-400 border-red-500/20 hover:bg-green-500/10 hover:text-green-400 hover:border-green-500/20'
                    }`}
                  >
                    {u.is_active ? 'ACTIVE' : 'INACTIVE'}
                  </button>
                </td>
                <td className="p-4">
                    <div className="flex gap-3">
                       <button onClick={() => onEdit(u)} className="text-slate-400 hover:text-white transition-colors">
                          <Icons.Edit className="w-4 h-4" />
                       </button>
                       <button onClick={() => handleDelete(u.id)} className="text-red-400 hover:text-red-300 transition-colors">
                          <Icons.Trash className="w-4 h-4" />
                       </button>
                    </div>
                </td>
              </tr>
            ))}
            {users.length === 0 && (
                <tr>
                    <td colSpan={3} className="p-8 text-center text-slate-500">No users found.</td>
                </tr>
            )}
          </tbody>
        </table>
      </div>
    </Card>
  );
};
