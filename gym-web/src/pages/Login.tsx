import React, { useState } from 'react';
import axios from 'axios';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const { login } = useAuth();
  const navigate = useNavigate();
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    try {
      const response = await axios.post('http://localhost:8080/api/auth/login', {
        email,
        password,
      });
      if (response.data.user.role !== 'admin' && response.data.user.role !== 'staff') {
        setError('Access Denied: Admin or Staff privileges required.');
        setIsLoading(false);
        return;
      }
      login(response.data.token);
      navigate('/');
    } catch (err) {
      setError('Invalid email or password.');
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-[#0f172a] relative overflow-hidden px-4">
      {/* Background Ambience */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-[10%] -left-[10%] w-96 h-96 bg-gym-brand/10 rounded-full blur-[100px] animate-pulse"></div>
        <div className="absolute -bottom-[10%] -right-[10%] w-96 h-96 bg-green-500/10 rounded-full blur-[100px] animate-pulse delay-1000"></div>
      </div>

      <div className="relative z-10 w-full max-w-md">
        <div className="glass border border-white/5 rounded-3xl p-8 md:p-10 shadow-2xl backdrop-blur-xl bg-black/40">
          <div className="text-center mb-10">
            <div className="inline-block p-4 rounded-full bg-gym-brand/10 mb-6 shadow-lg shadow-gym-brand/20 ring-1 ring-gym-brand/50">
              <svg 
                className="w-10 h-10 text-gym-brand" 
                fill="none" 
                stroke="currentColor" 
                viewBox="0 0 24 24" 
                width="40" 
                height="40"
                style={{ width: '2.5rem', height: '2.5rem' }}
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
            </div>
            <h1 className="text-4xl font-bold text-white tracking-tight mb-2 font-sans">Welcome Back</h1>
            <p className="text-slate-400">Sign in to manage your gym</p>
          </div>

          <form onSubmit={handleLogin} className="space-y-6">
            <div className="space-y-2">
              <label className="text-xs font-semibold text-gym-brand ml-1 uppercase tracking-wider">Email</label>
              <div className="relative">
                <input
                  type="email"
                  required
                  className="w-full px-4 py-4 bg-white/5 border border-white/10 rounded-xl text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-gym-brand/50 focus:border-gym-brand transition-all duration-200"
                  placeholder="admin@gym.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-xs font-semibold text-gym-brand ml-1 uppercase tracking-wider">Password</label>
              <div className="relative">
                <input
                  type="password"
                  required
                  className="w-full px-4 py-4 bg-white/5 border border-white/10 rounded-xl text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-gym-brand/50 focus:border-gym-brand transition-all duration-200"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
              </div>
            </div>

            {error && (
              <div className="p-4 rounded-lg bg-red-500/10 border border-red-500/20 flex items-center gap-3">
                <svg className="w-5 h-5 text-red-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <p className="text-sm text-red-400">{error}</p>
              </div>
            )}

            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-4 rounded-xl bg-gym-brand hover:bg-gym-400 text-slate-900 font-bold text-lg shadow-lg shadow-gym-brand/20 transition-all duration-200 transform hover:scale-[1.02] active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <div className="flex items-center justify-center gap-2">
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                  <span>Signing In...</span>
                </div>
              ) : (
                'Sign In to Dashboard'
              )}
            </button>
          </form>
        </div>
        
        <p className="text-center text-slate-500 text-sm mt-8">
          &copy; 2024 Gym Management System
        </p>
      </div>
    </div>
  );
};

export default Login;
