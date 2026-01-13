import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Card } from '../atoms/Card';
import { Button } from '../atoms/Button';
import { Icons } from '../atoms/Icon';

interface Attendance {
  id: number;
  trainer_id: number;
  trainer: {
    name: string;
    email: string;
    membership_status: string;
  };
  scanned_by: number;
  admin?: {
    name: string;
  };
  scan_time: string;
}

import { API_URL } from '../../config';

const AttendanceTable: React.FC = () => {
  const [logs, setLogs] = useState<Attendance[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  const fetchLogs = async () => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(`${API_URL}/management/attendance`, {
        headers: { Authorization: `Bearer ${token}` },
        params: { page, limit, start_date: startDate, end_date: endDate }
      });
      setLogs(res.data.data);
      setTotal(res.data.total);
    } catch (err) {
      console.error("Failed to fetch attendance logs", err);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [page, limit, startDate, endDate]);

  const totalPages = Math.ceil(total / limit);

  return (
    <Card className="min-h-[600px] flex flex-col">
       {/* Header & Controls */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
        <div>
           <h2 className="text-2xl font-bold text-white mb-1">Attendance History</h2>
           <p className="text-slate-400 text-sm">Monitor member check-ins and staff activity.</p>
        </div>
        
        <div className="flex items-center gap-3 bg-slate-900/50 p-2 rounded-xl border border-white/5">
           <div className="flex items-center gap-2 px-3 border-r border-white/10">
              <Icons.Chart className="w-4 h-4 text-slate-400" />
              <input 
                type="date"
                value={startDate}
                onChange={(e) => { setStartDate(e.target.value); setPage(1); }}
                className="bg-transparent text-sm text-white focus:outline-none [color-scheme:dark]"
              />
           </div>
           <span className="text-slate-500">to</span>
           <div className="flex items-center gap-2 px-3">
              <input 
                type="date"
                value={endDate}
                onChange={(e) => { setEndDate(e.target.value); setPage(1); }}
                className="bg-transparent text-sm text-white focus:outline-none [color-scheme:dark]"
              />
           </div>
        </div>
      </div>

      {/* Table */}
      <div className="flex-1 overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b border-white/10 text-slate-400 text-sm uppercase tracking-wider">
              <th className="py-4 px-4 font-medium">Member</th>
              <th className="py-4 px-4 font-medium">Time</th>
              <th className="py-4 px-4 font-medium">Status</th>
              <th className="py-4 px-4 font-medium">Scanned By</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/5">
            {logs.map((log) => (
              <tr key={log.id} className="group hover:bg-white/5 transition-colors">
                <td className="py-4 px-4">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-slate-700 flex items-center justify-center text-xs font-bold text-white">
                      {log.trainer?.name?.[0]?.toUpperCase() || '?'}
                    </div>
                    <div>
                       <div className="text-white font-medium">{log.trainer?.name || 'Unknown'}</div>
                       <div className="text-xs text-slate-500">{log.trainer?.email || ''}</div>
                    </div>
                  </div>
                </td>
                <td className="py-4 px-4 text-slate-300 whitespace-nowrap">
                   <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-full bg-slate-800 flex items-center justify-center text-slate-500 group-hover:bg-gym-brand/20 group-hover:text-gym-brand transition-colors">
                        <Icons.Chart className="w-4 h-4" />
                      </div>
                      <div className="flex flex-col">
                        <span className="font-semibold text-white">
                           {new Date(log.scan_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </span>
                        <span className="text-xs text-slate-500">
                           {new Date(log.scan_time).toLocaleDateString()}
                        </span>
                      </div>
                   </div>
                </td>
                <td className="py-4 px-4">
                   <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${
                      log.trainer?.membership_status === 'active' 
                        ? 'bg-green-500/10 text-green-500 border-green-500/20' 
                        : 'bg-red-500/10 text-red-500 border-red-500/20'
                   }`}>
                     {log.trainer?.membership_status?.toUpperCase() || 'UNKNOWN'}
                   </span>
                </td>
                <td className="py-4 px-4 text-slate-400">
                  {log.admin?.name || `Admin #${log.scanned_by}`}
                </td>
              </tr>
            ))}
            {logs.length === 0 && (
               <tr>
                 <td colSpan={4} className="py-12 text-center text-slate-500">
                   No attendance records found for this period.
                 </td>
               </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="mt-8 flex items-center justify-between border-t border-white/5 pt-4">
         <span className="text-sm text-slate-400">
           Page <strong className="text-white">{page}</strong> of <strong className="text-white">{totalPages || 1}</strong>
         </span>
         <div className="flex gap-2">
            <Button 
               variant="secondary" 
               disabled={page <= 1} 
               onClick={() => setPage(p => Math.max(1, p - 1))}
               className="text-sm px-3 py-1"
            >
               Previous
            </Button>
            <Button 
               variant="secondary" 
               disabled={page >= totalPages} 
               onClick={() => setPage(p => p + 1)}
               className="text-sm px-3 py-1"
            >
               Next
            </Button>
         </div>
      </div>
    </Card>
  );
};

export default AttendanceTable;
