import React from 'react'
import { Link } from 'react-router-dom'

const Footer = () => {
  const currentYear = new Date().getFullYear()

  const footerSections = [
    {
      title: 'Modules',
      links: [
        { name: 'ISMAIL Services', href: '/services' },
        { name: 'ISMAIL Shop', href: '/shop' },
        { name: 'ISMAIL Booking', href: '/booking' },
        { name: 'ISMAIL Immobilier', href: '/immobilier' },
        { name: 'ISMAIL Recouvrement', href: '/recouvrement' },
      ]
    },
    {
      title: 'Entreprise',
      links: [
        { name: 'À propos', href: '/about' },
        { name: 'Carrières', href: '/careers' },
        { name: 'Partenaires', href: '/partners' },
        { name: 'Presse', href: '/press' },
        { name: 'Blog', href: '/blog' },
      ]
    },
    {
      title: 'Support',
      links: [
        { name: 'Centre d\'aide', href: '/help' },
        { name: 'Contact', href: '/contact' },
        { name: 'Documentation', href: '/docs' },
        { name: 'API', href: '/api' },
        { name: 'Statut', href: '/status' },
      ]
    },
    {
      title: 'Légal',
      links: [
        { name: 'Conditions d\'utilisation', href: '/terms' },
        { name: 'Politique de confidentialité', href: '/privacy' },
        { name: 'Cookies', href: '/cookies' },
        { name: 'RGPD', href: '/gdpr' },
        { name: 'Sécurité', href: '/security' },
      ]
    }
  ]

  return (
    <footer className="bg-neutral-900 text-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {/* Section principale */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-8">
          {/* Logo et description */}
          <div className="lg:col-span-1">
            <div className="flex items-center space-x-2 mb-4">
              <div className="w-8 h-8 bg-primary-orange rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-lg">I</span>
              </div>
              <span className="text-xl font-bold">ISMAIL</span>
            </div>
            <p className="text-neutral-400 text-sm mb-4">
              Plateforme numérique unifiée pour l'Afrique de l'Ouest. 
              Services, commerce, réservations et plus encore.
            </p>
            <div className="flex space-x-4">
              {/* Réseaux sociaux */}
              <a href="#" className="text-neutral-400 hover:text-white transition-colors">
                <span className="sr-only">Facebook</span>
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M20 10C20 4.477 15.523 0 10 0S0 4.477 0 10c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V10h2.54V7.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V10h2.773l-.443 2.89h-2.33v6.988C16.343 19.128 20 14.991 20 10z" clipRule="evenodd" />
                </svg>
              </a>
              <a href="#" className="text-neutral-400 hover:text-white transition-colors">
                <span className="sr-only">Twitter</span>
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M6.29 18.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0020 3.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.073 4.073 0 01.8 7.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 010 16.407a11.616 11.616 0 006.29 1.84" />
                </svg>
              </a>
              <a href="#" className="text-neutral-400 hover:text-white transition-colors">
                <span className="sr-only">LinkedIn</span>
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.338 16.338H13.67V12.16c0-.995-.017-2.277-1.387-2.277-1.39 0-1.601 1.086-1.601 2.207v4.248H8.014v-8.59h2.559v1.174h.037c.356-.675 1.227-1.387 2.526-1.387 2.703 0 3.203 1.778 3.203 4.092v4.711zM5.005 6.575a1.548 1.548 0 11-.003-3.096 1.548 1.548 0 01.003 3.096zm-1.337 9.763H6.34v-8.59H3.667v8.59zM17.668 1H2.328C1.595 1 1 1.581 1 2.298v15.403C1 18.418 1.595 19 2.328 19h15.34c.734 0 1.332-.582 1.332-1.299V2.298C19 1.581 18.402 1 17.668 1z" clipRule="evenodd" />
                </svg>
              </a>
            </div>
          </div>

          {/* Liens */}
          {footerSections.map((section) => (
            <div key={section.title}>
              <h3 className="text-sm font-semibold text-white uppercase tracking-wider mb-4">
                {section.title}
              </h3>
              <ul className="space-y-2">
                {section.links.map((link) => (
                  <li key={link.name}>
                    <Link
                      to={link.href}
                      className="text-neutral-400 hover:text-white transition-colors text-sm"
                    >
                      {link.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Séparateur */}
        <div className="border-t border-neutral-800 mt-8 pt-8">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <p className="text-neutral-400 text-sm">
              © {currentYear} ISMAIL Platform. Tous droits réservés.
            </p>
            <div className="flex space-x-6 mt-4 md:mt-0">
              <span className="text-neutral-400 text-sm">
                Conforme RGPD/UEMOA
              </span>
              <span className="text-neutral-400 text-sm">
                Sécurisé SSL
              </span>
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
}

export default Footer
