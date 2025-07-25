import React, { useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { 
  Bars3Icon, 
  XMarkIcon,
  UserCircleIcon,
  BellIcon,
  MagnifyingGlassIcon
} from '@heroicons/react/24/outline'

const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const location = useLocation()

  const navigation = [
    { name: 'Accueil', href: '/', current: location.pathname === '/' },
    { name: 'Services', href: '/services', current: location.pathname === '/services' },
    { name: 'Shop', href: '/shop', current: location.pathname === '/shop' },
    { name: 'Booking', href: '/booking', current: location.pathname === '/booking' },
    { name: 'Immobilier', href: '/immobilier', current: location.pathname === '/immobilier' },
    { name: 'Recouvrement', href: '/recouvrement', current: location.pathname === '/recouvrement' },
  ]

  return (
    <header className="bg-white shadow-sm border-b border-neutral-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <div className="flex items-center">
            <Link to="/" className="flex items-center space-x-2">
              <div className="w-8 h-8 bg-primary-orange rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-lg">I</span>
              </div>
              <span className="text-xl font-bold text-neutral-900">ISMAIL</span>
            </Link>
          </div>

          {/* Navigation Desktop */}
          <nav className="hidden md:flex space-x-8">
            {navigation.map((item) => (
              <Link
                key={item.name}
                to={item.href}
                className={`px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                  item.current
                    ? 'text-primary-orange bg-orange-50'
                    : 'text-neutral-700 hover:text-primary-orange hover:bg-neutral-100'
                }`}
              >
                {item.name}
              </Link>
            ))}
          </nav>

          {/* Actions Desktop */}
          <div className="hidden md:flex items-center space-x-4">
            {/* Recherche */}
            <div className="relative">
              <MagnifyingGlassIcon className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-neutral-400" />
              <input
                type="text"
                placeholder="Rechercher..."
                className="pl-10 pr-4 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-primary-orange focus:border-transparent"
              />
            </div>

            {/* Notifications */}
            <button className="p-2 text-neutral-400 hover:text-neutral-600 relative">
              <BellIcon className="w-6 h-6" />
              <span className="absolute top-0 right-0 w-2 h-2 bg-error rounded-full"></span>
            </button>

            {/* Profil */}
            <Link to="/profile" className="p-2 text-neutral-400 hover:text-neutral-600">
              <UserCircleIcon className="w-6 h-6" />
            </Link>

            {/* Bouton Connexion */}
            <Link to="/auth" className="btn-primary">
              Se connecter
            </Link>
          </div>

          {/* Menu Mobile */}
          <div className="md:hidden">
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="p-2 text-neutral-400 hover:text-neutral-600"
            >
              {isMenuOpen ? (
                <XMarkIcon className="w-6 h-6" />
              ) : (
                <Bars3Icon className="w-6 h-6" />
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Menu Mobile */}
      {isMenuOpen && (
        <div className="md:hidden">
          <div className="px-2 pt-2 pb-3 space-y-1 sm:px-3 bg-white border-t border-neutral-200">
            {navigation.map((item) => (
              <Link
                key={item.name}
                to={item.href}
                className={`block px-3 py-2 rounded-md text-base font-medium ${
                  item.current
                    ? 'text-primary-orange bg-orange-50'
                    : 'text-neutral-700 hover:text-primary-orange hover:bg-neutral-100'
                }`}
                onClick={() => setIsMenuOpen(false)}
              >
                {item.name}
              </Link>
            ))}
            <div className="pt-4 pb-3 border-t border-neutral-200">
              <Link
                to="/auth"
                className="block w-full text-center btn-primary"
                onClick={() => setIsMenuOpen(false)}
              >
                Se connecter
              </Link>
            </div>
          </div>
        </div>
      )}
    </header>
  )
}

export default Header
