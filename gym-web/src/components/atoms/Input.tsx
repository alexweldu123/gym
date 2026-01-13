import React from 'react';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

export const Input: React.FC<InputProps> = ({ label, error, className = '', ...props }) => {
  return (
    <div className="w-full">
      {label && (
        <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">
          {label}
        </label>
      )}
      <input
        className={`w-full px-4 py-3 rounded-xl bg-slate-800 border-2 border-slate-700 text-white placeholder-slate-400 
        focus:outline-none focus:ring-2 focus:ring-gym-brand/50 focus:border-gym-brand transition-all 
        hover:bg-slate-700/50 hover:border-slate-500 ${error ? 'border-red-500' : ''} ${className}`}
        {...props}
      />
      {error && <p className="text-red-500 text-xs mt-1">{error}</p>}
    </div>
  );
};
