import { useState, useEffect } from 'react';
import axios from 'axios';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';

import { Card } from '../components/atoms/Card';
import { Icons } from '../components/atoms/Icon';
import { Button } from '../components/atoms/Button';
import { StatCard } from '../components/molecules/StatCard';
import { MembersTable } from '../components/organisms/MembersTable';
import { MemberModal } from '../components/organisms/MemberModal';
import { UserModal } from '../components/organisms/UserModal';
import { UsersTable } from '../components/organisms/UsersTable';
import Attendance from './Attendance';
import { API_URL } from '../config';

// -- VIEWS --

const StatsView = () => {
  const [stats, setStats] = useState<any>(null);
  const [chartData, setChartData] = useState<any[]>([]);

  useEffect(() => {
    const fetchData = async () => {
      const sRes = await axios.get(`${API_URL}/admin/stats`);
      setStats(sRes.data.data);
      const cRes = await axios.get(`${API_URL}/admin/attendance/chart`);
      setChartData(cRes.data.data || []);
    };
    fetchData();
  }, []);

  if (!stats) return <div className="text-white">Loading stats...</div>;

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-white">Dashboard Overview</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard title="Total Members" value={stats.total_members} color="bg-blue-500" />
        <StatCard title="Active Members" value={stats.active_members} color="bg-green-500" />
        <StatCard title="Total Revenue" value={`$${stats.estimated_revenue}`} color="bg-purple-500" />
        <StatCard title="Today's Visits" value={stats.today_attendance} color="bg-orange-500" />
      </div>

      <Card className="h-96">
        <h3 className="text-white font-semibold mb-6">Attendance Trends (Last 7 Days)</h3>
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={chartData}>
            <XAxis dataKey="date" stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} />
            <YAxis stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} />
            <Tooltip 
              contentStyle={{ backgroundColor: '#1e293b', border: 'none', borderRadius: '8px', color: '#fff' }} 
              itemStyle={{ color: '#fff' }}
              cursor={{ fill: 'rgba(255,255,255,0.05)' }}
            />
            <Bar dataKey="count" fill="#3b82f6" radius={[4, 4, 0, 0]} barSize={40} />
          </BarChart>
        </ResponsiveContainer>
      </Card>
    </div>
  );
};

const PackagesView = () => {
  const [packages, setPackages] = useState<any[]>([]);
  const [form, setForm] = useState({ id: 0, name: '', days: 30, price: 0 });
  const [isEditing, setIsEditing] = useState(false);

  const fetchPackages = async () => {
    const res = await axios.get(`${API_URL}/management/packages`);
    setPackages(res.data.data);
  };
  useEffect(() => { fetchPackages(); }, []);

  const handleSave = async () => {
    if (isEditing) {
      await axios.put(`${API_URL}/admin/packages/${form.id}`, { 
        name: form.name, 
        duration_days: Number(form.days), 
        price: Number(form.price), description: 'Web' 
      });
      setIsEditing(false);
    } else {
      await axios.post(`${API_URL}/admin/packages`, { 
        name: form.name, 
        duration_days: Number(form.days), 
        price: Number(form.price), description: 'Web' 
      });
    }
    fetchPackages();
    setForm({ id: 0, name: '', days: 30, price: 0 });
  };

  const handleEdit = (p: any) => {
    setForm({ id: p.id, name: p.name, days: p.duration_days, price: p.price });
    setIsEditing(true);
  };

  const handleDelete = async (id: number) => {
    if (window.confirm('Are you sure?')) {
      await axios.delete(`${API_URL}/admin/packages/${id}`);
      fetchPackages();
    }
  };

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-white">Membership Plans</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Editor Card */}
        <Card className="border-dashed border-2 border-slate-700 bg-transparent flex flex-col justify-center space-y-4">
          <h3 className="text-lg font-semibold text-slate-300">{isEditing ? 'Edit Plan' : 'Create New Plan'}</h3>
          <input className="input-field" placeholder="Plan Name" value={form.name} onChange={e => setForm({...form, name: e.target.value})} />
          <div className="flex gap-2">
            <input className="input-field" type="number" placeholder="Days" value={form.days} onChange={e => setForm({...form, days: Number(e.target.value)})} />
            <input className="input-field" type="number" placeholder="Price" value={form.price} onChange={e => setForm({...form, price: Number(e.target.value)})} />
          </div>
          <div className="flex gap-2">
             <Button onClick={handleSave} className="flex-1">{isEditing ? 'Update' : 'Create'}</Button>
             {isEditing && <Button variant="secondary" onClick={() => { setIsEditing(false); setForm({ id: 0, name: '', days: 30, price: 0 }); }}>Cancel</Button>}
          </div>
        </Card>

        {/* Existing Packages */}
        {packages.map(p => (
          <Card key={p.id} className="relative group hover:border-blue-500/30 transition-all">
            <div className="flex justify-between items-start mb-4">
               <div>
                  <h3 className="text-xl font-bold text-white">{p.name}</h3>
                  <p className="text-sm text-slate-400">{p.duration_days} Days</p>
               </div>
               <p className="text-2xl font-bold text-blue-400">${p.price}</p>
            </div>
            <div className="flex gap-2 mt-4 pt-4 border-t border-slate-800">
              <Button onClick={() => handleEdit(p)} variant="secondary" className="flex-1 text-sm py-2">Edit</Button>
              <Button onClick={() => handleDelete(p.id)} variant="danger" className="flex-1 text-sm py-2">Delete</Button>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
};

const MembersView = () => {
  const [members, setMembers] = useState<any[]>([]);
  const [packages, setPackages] = useState<any[]>([]);
  const [showMemberModal, setShowMemberModal] = useState(false);
  const [editMemberData, setEditMemberData] = useState(null);

  const fetchData = async () => {
    const mRes = await axios.get(`${API_URL}/management/members`);
    setMembers(mRes.data.data);
    const pRes = await axios.get(`${API_URL}/management/packages`);
    setPackages(pRes.data.data);
  };
  useEffect(() => { fetchData(); }, []);

  const handleEdit = (member: any) => {
    setEditMemberData(member);
    setShowMemberModal(true);
  };

  const handleAdd = () => {
    setEditMemberData(null);
    setShowMemberModal(true);
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold text-white">Members Directory</h2>
        <Button onClick={handleAdd}>Add Member</Button>
      </div>

      {showMemberModal && (
         <MemberModal 
           onClose={() => setShowMemberModal(false)} 
           onSuccess={fetchData} 
           initialData={editMemberData}
         />
      )}

      <MembersTable members={members} packages={packages} onUpdate={fetchData} onEdit={handleEdit} />
    </div>
  );
};

const UsersView = () => {
  const [users, setUsers] = useState<any[]>([]);
  const [showUserModal, setShowUserModal] = useState(false);
  const [editUserData, setEditUserData] = useState(null);
  const [selectedRole, setSelectedRole] = useState('staff');

  const fetchUsers = async () => {
    try {
      const res = await axios.get(`${API_URL}/admin/users?role=${selectedRole}`);
      setUsers(res.data.data);
    } catch (e) {
      console.error(e);
      setUsers([]);
    }
  };

  useEffect(() => { fetchUsers(); }, [selectedRole]);

  const handleEdit = (u: any) => {
    setEditUserData(u);
    setShowUserModal(true);
  };

  const handleAdd = () => {
    setEditUserData(null);
    setShowUserModal(true);
  };

  return (
    <div className="space-y-6">
       <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold text-white">Manage Staff & Trainers</h2>
        <Button onClick={handleAdd}>{`Add ${selectedRole === 'staff' ? 'Staff' : 'Trainer'}`}</Button>
      </div>
      
      <div className="flex gap-4 border-b border-slate-700">
         <button 
           className={`pb-2 px-4 ${selectedRole === 'staff' ? 'text-gym-brand border-b-2 border-gym-brand' : 'text-slate-400'}`}
           onClick={() => setSelectedRole('staff')}
         >
           Staff
         </button>
         <button 
           className={`pb-2 px-4 ${selectedRole === 'trainer' ? 'text-gym-brand border-b-2 border-gym-brand' : 'text-slate-400'}`}
           onClick={() => setSelectedRole('trainer')}
         >
           Trainers
         </button>
      </div>

      {showUserModal && (
         <UserModal 
           onClose={() => setShowUserModal(false)}
           onSuccess={fetchUsers}
           initialData={editUserData}
         />
      )}

      <UsersTable users={users} onUpdate={fetchUsers} onEdit={handleEdit} />
    </div>
  );
};
  
const LogoutView = () => {
  const navigate = useNavigate();
  useEffect(() => {
    localStorage.removeItem('token');
    navigate('/login');
  }, []);
  return null;
};

const SidebarItem = ({ icon, label, active, onClick }: { icon: any, label: string, active: boolean, onClick: () => void }) => (
  <button 
    onClick={onClick}
    className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-xl transition-all duration-200 group ${active ? 'bg-gym-brand text-slate-900 font-bold shadow-lg shadow-gym-brand/20' : 'text-slate-400 hover:bg-white/5 hover:text-white'}`}
  >
    {icon}
    <span className="">{label}</span>
  </button>
);

export const Dashboard = () => {
  const { user } = useAuth(); // Get user from context
  const [activeTab, setActiveTab] = useState('dashboard');
  
  const renderContent = () => {
    switch(activeTab) {
      case 'dashboard': return <StatsView />;
      case 'members': return <MembersView />;
      case 'packages': return user?.role === 'admin' ? <PackagesView /> : <div className="text-white">Access Denied</div>;
      case 'users': return user?.role === 'admin' ? <UsersView /> : <div className="text-white">Access Denied</div>;
      case 'attendance': return user?.role === 'admin' ? <Attendance /> : <div className="text-white">Access Denied</div>;
      case 'logout': return <LogoutView />;
      default: return <StatsView />;
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 flex font-sans">
      {/* Sidebar */}
      <aside className="w-64 bg-slate-900 border-r border-white/5 flex flex-col fixed h-full z-20">
        <div className="p-6">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-gym-brand to-gym-400 flex items-center justify-center">
              <span className="text-slate-900 font-bold">G</span>
            </div>
            <span className="text-xl font-bold text-white tracking-tight">GymOS</span>
          </div>
        </div>

        <nav className="flex-1 px-4 space-y-2 mt-4">
          <SidebarItem icon={<Icons.Chart />} label="Dashboard" active={activeTab === 'dashboard'} onClick={() => setActiveTab('dashboard')} />
          <SidebarItem icon={<Icons.Users />} label="Members" active={activeTab === 'members'} onClick={() => setActiveTab('members')} />
          
          {user?.role === 'admin' && (
            <>
              <SidebarItem icon={<Icons.Package />} label="Packages" active={activeTab === 'packages'} onClick={() => setActiveTab('packages')} />
              <SidebarItem icon={<Icons.Users className="w-5 h-5" />} label="Staff & Trainers" active={activeTab === 'users'} onClick={() => setActiveTab('users')} />
              <SidebarItem icon={<Icons.Chart className="w-5 h-5" />} label="Attendance" active={activeTab === 'attendance'} onClick={() => setActiveTab('attendance')} />
            </>
          )}
          
          <SidebarItem icon={<Icons.Logout />} label="Logout" active={false} onClick={() => setActiveTab('logout')} />
        </nav>

        <div className="p-4 border-t border-white/5">
          <div className="flex items-center gap-3 px-2">
            <div className="w-8 h-8 rounded-full bg-slate-800 ring-1 ring-white/10" />
            <div>
              <div className="text-sm font-medium text-white capitalize">{user?.role || 'User'}</div>
              <div className="text-xs text-slate-500 truncate w-32">{user?.email || ''}</div>
            </div>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 ml-64 p-8 relative">
        <div className="max-w-7xl mx-auto relative z-10">
          {renderContent()}
        </div>
      </main>
      
       {/* Styles block */}
       <style>{`
        .input-field {
          @apply w-full px-4 py-3 rounded-xl bg-slate-800 border-2 border-slate-700 text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-gym-brand/50 focus:border-gym-brand transition-all hover:bg-slate-700/50 hover:border-slate-500;
        }
      `}</style>
    </div>
  );
};
export default Dashboard;
 