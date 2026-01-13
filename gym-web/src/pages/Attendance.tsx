import React from 'react';
import { Box } from '@mui/material';
import AttendanceTable from '../components/organisms/AttendanceTable';

const Attendance: React.FC = () => {
  return (
    <Box p={3}>
      <AttendanceTable />
    </Box>
  );
};

export default Attendance;
