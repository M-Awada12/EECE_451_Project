import React, { useEffect } from 'react';
import { BrowserRouter, Routes, Route } from "react-router-dom";
import NavBar from "./components/NavBar/NavBar";
import Footer from "./components/Footer/Footer";
import ConnectionTable from './components/ConnectionTable/ConnectionTable';
import Statistics from './components/Statistics/Statistics';

function App() {

  useEffect(() => {
    document.title = 'Mobile Network Analyzer';
  }, []);

  return (
    <BrowserRouter>
      <NavBar />
      <Routes>
        <Route path="/" element={<ConnectionTable />} />
        <Route path="/details/:deviceId" element={<Statistics />} />
      </Routes>
      <Footer />
    </BrowserRouter>
  );
}

export default App;
