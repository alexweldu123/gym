import React from 'react';
import { Card } from '../atoms/Card';

interface StatCardProps {
  title: string;
  value: string | number;
  color: string;
}

export const StatCard: React.FC<StatCardProps> = ({ title, value, color }) => (
  <Card className="relative overflow-hidden group">
    <div className={`absolute top-0 right-0 w-20 h-20 ${color} opacity-10 rounded-full blur-2xl -mr-8 -mt-8 transition-opacity group-hover:opacity-20`}></div>
    <h3 className="text-slate-400 text-sm font-medium uppercase tracking-wider mb-2">{title}</h3>
    <p className="text-3xl font-bold text-white">{value}</p>
  </Card>
);
