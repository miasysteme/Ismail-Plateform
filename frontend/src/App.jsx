import React from 'react'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import Header from './components/layout/Header'
import Footer from './components/layout/Footer'
import HomePage from './pages/HomePage'
import ServicesPage from './pages/ServicesPage'
import ShopPage from './pages/ShopPage'
import BookingPage from './pages/BookingPage'
import RealEstatePage from './pages/RealEstatePage'
import RecoveryPage from './pages/RecoveryPage'
import AuthPage from './pages/AuthPage'
import DashboardPage from './pages/DashboardPage'
import ProfilePage from './pages/ProfilePage'

function App() {
  return (
    <Router>
      <div className="min-h-screen flex flex-col bg-neutral-50">
        <Header />
        
        <main className="flex-1">
          <Routes>
            {/* Page d'accueil */}
            <Route path="/" element={<HomePage />} />
            
            {/* Modules principaux */}
            <Route path="/services" element={<ServicesPage />} />
            <Route path="/shop" element={<ShopPage />} />
            <Route path="/booking" element={<BookingPage />} />
            <Route path="/immobilier" element={<RealEstatePage />} />
            <Route path="/recouvrement" element={<RecoveryPage />} />
            
            {/* Authentification et compte */}
            <Route path="/auth" element={<AuthPage />} />
            <Route path="/dashboard" element={<DashboardPage />} />
            <Route path="/profile" element={<ProfilePage />} />
          </Routes>
        </main>
        
        <Footer />
      </div>
    </Router>
  )
}

export default App
