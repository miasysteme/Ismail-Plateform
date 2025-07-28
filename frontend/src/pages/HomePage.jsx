import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import {
  CogIcon,
  ShoppingBagIcon,
  CalendarDaysIcon,
  HomeModernIcon,
  CurrencyDollarIcon,
  ArrowRightIcon,
  CheckCircleIcon,
  StarIcon,
  SignalIcon,
  ExclamationTriangleIcon
} from '@heroicons/react/24/outline'

const HomePage = () => {
  const modules = [
    {
      name: 'ISMAIL Services',
      description: 'Trouvez et réservez des services professionnels près de chez vous',
      icon: CogIcon,
      href: '/services',
      color: 'bg-secondary-teal',
      features: ['Plomberie', 'Électricité', 'Ménage', 'Jardinage']
    },
    {
      name: 'ISMAIL Shop',
      description: 'Marketplace pour acheter et vendre vos produits en ligne',
      icon: ShoppingBagIcon,
      href: '/shop',
      color: 'bg-primary-green',
      features: ['E-commerce', 'Livraison', 'Paiement sécurisé', 'Support 24/7']
    },
    {
      name: 'ISMAIL Booking',
      description: 'Réservez des événements, salles et prestations facilement',
      icon: CalendarDaysIcon,
      href: '/booking',
      color: 'bg-secondary-purple',
      features: ['Événements', 'Salles', 'Restaurants', 'Spectacles']
    },
    {
      name: 'ISMAIL Immobilier',
      description: 'Achetez, vendez ou louez des biens immobiliers',
      icon: HomeModernIcon,
      href: '/immobilier',
      color: 'bg-primary-blue',
      features: ['Vente', 'Location', 'Estimation', 'Visite virtuelle']
    },
    {
      name: 'ISMAIL Recouvrement',
      description: 'Solutions professionnelles de recouvrement de créances',
      icon: CurrencyDollarIcon,
      href: '/recouvrement',
      color: 'bg-secondary-gold',
      features: ['Recouvrement', 'Médiation', 'Juridique', 'Reporting']
    }
  ]

  const stats = [
    { name: 'Utilisateurs actifs', value: '50K+' },
    { name: 'Transactions', value: '1M+' },
    { name: 'Partenaires', value: '5K+' },
    { name: 'Pays couverts', value: '15' }
  ]

  // Test de connexion API
  const [apiStatus, setApiStatus] = useState('checking')
  const [apiData, setApiData] = useState(null)

  useEffect(() => {
    const testAPI = async () => {
      try {
        const response = await fetch('https://ismail-plateform.onrender.com/')
        const data = await response.json()
        setApiStatus('connected')
        setApiData(data)
      } catch (err) {
        setApiStatus('error')
        console.error('API Error:', err)
      }
    }

    testAPI()
  }, [])

  const testimonials = [
    {
      name: 'Aminata Diallo',
      role: 'Entrepreneure',
      content: 'ISMAIL a révolutionné ma façon de gérer mon business. Tout est centralisé !',
      rating: 5
    },
    {
      name: 'Moussa Traoré',
      role: 'Commerçant',
      content: 'Grâce à ISMAIL Shop, mes ventes ont augmenté de 300% en 6 mois.',
      rating: 5
    },
    {
      name: 'Fatou Sow',
      role: 'Propriétaire',
      content: 'Le module immobilier m\'a permis de louer mes biens rapidement.',
      rating: 5
    }
  ]

  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <section className="bg-gradient-to-br from-primary-orange to-secondary-gold text-white py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h1 className="text-4xl md:text-6xl font-bold mb-6 animate-fade-in">
              Bienvenue sur <span className="text-yellow-200">ISMAIL</span>
            </h1>
            <p className="text-xl md:text-2xl mb-8 text-orange-100 max-w-3xl mx-auto animate-slide-up">
              La plateforme numérique unifiée qui révolutionne l'Afrique de l'Ouest. 
              Services, commerce, réservations et bien plus encore.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center animate-slide-up">
              <Link to="/auth" className="btn-secondary bg-white text-primary-orange hover:bg-orange-50">
                Commencer maintenant
              </Link>
              <Link to="/services" className="btn-ghost border-white text-white hover:bg-white hover:text-primary-orange">
                Découvrir les services
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Modules Section */}
      <section className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-neutral-900 mb-4">
              Nos 5 Modules Intégrés
            </h2>
            <p className="text-lg text-neutral-600 max-w-2xl mx-auto">
              Une seule plateforme, cinq solutions complètes pour tous vos besoins
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {modules.map((module, index) => (
              <div key={module.name} className="card hover:shadow-ismail group">
                <div className={`w-12 h-12 ${module.color} rounded-lg flex items-center justify-center mb-4 group-hover:scale-110 transition-transform`}>
                  <module.icon className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-xl font-semibold text-neutral-900 mb-2">
                  {module.name}
                </h3>
                <p className="text-neutral-600 mb-4">
                  {module.description}
                </p>
                <ul className="space-y-1 mb-6">
                  {module.features.map((feature) => (
                    <li key={feature} className="flex items-center text-sm text-neutral-500">
                      <CheckCircleIcon className="w-4 h-4 text-primary-green mr-2" />
                      {feature}
                    </li>
                  ))}
                </ul>
                <Link 
                  to={module.href}
                  className="inline-flex items-center text-primary-orange hover:text-orange-600 font-medium"
                >
                  En savoir plus
                  <ArrowRightIcon className="w-4 h-4 ml-1 group-hover:translate-x-1 transition-transform" />
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* API Status Section */}
      <section className="py-8 bg-neutral-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="bg-white rounded-lg shadow-sm p-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                {apiStatus === 'checking' && (
                  <>
                    <SignalIcon className="h-6 w-6 text-yellow-500 animate-pulse" />
                    <span className="text-sm text-neutral-600">Vérification de la connexion API...</span>
                  </>
                )}
                {apiStatus === 'connected' && (
                  <>
                    <CheckCircleIcon className="h-6 w-6 text-green-500" />
                    <span className="text-sm text-green-600 font-medium">✅ Backend connecté (Render + Supabase)</span>
                  </>
                )}
                {apiStatus === 'error' && (
                  <>
                    <ExclamationTriangleIcon className="h-6 w-6 text-red-500" />
                    <span className="text-sm text-red-600">❌ Erreur de connexion API</span>
                  </>
                )}
              </div>
              {apiData && (
                <div className="text-xs text-neutral-500">
                  Version: {apiData.version} | Status: {apiData.status}
                </div>
              )}
            </div>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-16 bg-neutral-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            {stats.map((stat) => (
              <div key={stat.name} className="text-center">
                <div className="text-3xl md:text-4xl font-bold text-primary-orange mb-2">
                  {stat.value}
                </div>
                <div className="text-neutral-600">
                  {stat.name}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-neutral-900 mb-4">
              Ce que disent nos utilisateurs
            </h2>
            <p className="text-lg text-neutral-600">
              Rejoignez des milliers d'utilisateurs satisfaits
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {testimonials.map((testimonial, index) => (
              <div key={index} className="card">
                <div className="flex items-center mb-4">
                  {[...Array(testimonial.rating)].map((_, i) => (
                    <StarIcon key={i} className="w-5 h-5 text-secondary-gold fill-current" />
                  ))}
                </div>
                <p className="text-neutral-700 mb-4 italic">
                  "{testimonial.content}"
                </p>
                <div>
                  <div className="font-semibold text-neutral-900">
                    {testimonial.name}
                  </div>
                  <div className="text-sm text-neutral-500">
                    {testimonial.role}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 bg-primary-blue text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">
            Prêt à commencer ?
          </h2>
          <p className="text-xl mb-8 text-blue-100">
            Rejoignez la révolution numérique de l'Afrique de l'Ouest
          </p>
          <Link to="/auth" className="btn-primary bg-primary-orange hover:bg-orange-600">
            Créer mon compte gratuitement
          </Link>
        </div>
      </section>
    </div>
  )
}

export default HomePage
