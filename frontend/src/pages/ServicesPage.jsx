import React, { useState } from 'react'
import { 
  MagnifyingGlassIcon,
  MapPinIcon,
  StarIcon,
  ClockIcon,
  CurrencyDollarIcon,
  FunnelIcon
} from '@heroicons/react/24/outline'

const ServicesPage = () => {
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('all')
  const [location, setLocation] = useState('')

  const categories = [
    { id: 'all', name: 'Tous les services' },
    { id: 'plumbing', name: 'Plomberie' },
    { id: 'electrical', name: 'Électricité' },
    { id: 'cleaning', name: 'Ménage' },
    { id: 'gardening', name: 'Jardinage' },
    { id: 'painting', name: 'Peinture' },
    { id: 'repair', name: 'Réparation' },
    { id: 'beauty', name: 'Beauté' },
    { id: 'tutoring', name: 'Cours particuliers' }
  ]

  const services = [
    {
      id: 1,
      title: 'Plombier professionnel',
      provider: 'Mamadou Diallo',
      category: 'plumbing',
      rating: 4.8,
      reviews: 127,
      price: '15,000',
      currency: 'FCFA',
      location: 'Dakar, Sénégal',
      image: '/api/placeholder/300/200',
      description: 'Réparation et installation de plomberie, disponible 24h/24',
      responseTime: '< 2h',
      verified: true
    },
    {
      id: 2,
      title: 'Électricien certifié',
      provider: 'Fatou Sow',
      category: 'electrical',
      rating: 4.9,
      reviews: 89,
      price: '20,000',
      currency: 'FCFA',
      location: 'Abidjan, Côte d\'Ivoire',
      image: '/api/placeholder/300/200',
      description: 'Installation électrique et dépannage d\'urgence',
      responseTime: '< 1h',
      verified: true
    },
    {
      id: 3,
      title: 'Service de ménage',
      provider: 'Aïcha Traoré',
      category: 'cleaning',
      rating: 4.7,
      reviews: 203,
      price: '8,000',
      currency: 'FCFA',
      location: 'Bamako, Mali',
      image: '/api/placeholder/300/200',
      description: 'Ménage complet pour maisons et bureaux',
      responseTime: '< 4h',
      verified: true
    },
    {
      id: 4,
      title: 'Jardinier paysagiste',
      provider: 'Ousmane Kone',
      category: 'gardening',
      rating: 4.6,
      reviews: 156,
      price: '12,000',
      currency: 'FCFA',
      location: 'Ouagadougou, Burkina Faso',
      image: '/api/placeholder/300/200',
      description: 'Entretien de jardins et aménagement paysager',
      responseTime: '< 6h',
      verified: false
    }
  ]

  const filteredServices = services.filter(service => {
    const matchesSearch = service.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         service.provider.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesCategory = selectedCategory === 'all' || service.category === selectedCategory
    const matchesLocation = location === '' || service.location.toLowerCase().includes(location.toLowerCase())
    
    return matchesSearch && matchesCategory && matchesLocation
  })

  return (
    <div className="min-h-screen bg-neutral-50">
      {/* Header */}
      <div className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <h1 className="text-3xl font-bold text-neutral-900 mb-2">
            ISMAIL Services
          </h1>
          <p className="text-lg text-neutral-600">
            Trouvez et réservez des services professionnels près de chez vous
          </p>
        </div>
      </div>

      {/* Filtres et recherche */}
      <div className="bg-white border-b border-neutral-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Recherche */}
            <div className="relative">
              <MagnifyingGlassIcon className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-neutral-400" />
              <input
                type="text"
                placeholder="Rechercher un service..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-primary-orange focus:border-transparent"
              />
            </div>

            {/* Localisation */}
            <div className="relative">
              <MapPinIcon className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-neutral-400" />
              <input
                type="text"
                placeholder="Ville ou région..."
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-primary-orange focus:border-transparent"
              />
            </div>

            {/* Catégorie */}
            <div className="relative">
              <FunnelIcon className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-neutral-400" />
              <select
                value={selectedCategory}
                onChange={(e) => setSelectedCategory(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-primary-orange focus:border-transparent appearance-none"
              >
                {categories.map(category => (
                  <option key={category.id} value={category.id}>
                    {category.name}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>
      </div>

      {/* Résultats */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-xl font-semibold text-neutral-900">
            {filteredServices.length} service(s) trouvé(s)
          </h2>
          <select className="border border-neutral-300 rounded-lg px-3 py-2 text-sm">
            <option>Trier par pertinence</option>
            <option>Prix croissant</option>
            <option>Prix décroissant</option>
            <option>Mieux notés</option>
            <option>Plus récents</option>
          </select>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredServices.map(service => (
            <div key={service.id} className="card hover:shadow-ismail group cursor-pointer">
              {/* Image */}
              <div className="relative mb-4">
                <img
                  src={service.image}
                  alt={service.title}
                  className="w-full h-48 object-cover rounded-lg"
                />
                {service.verified && (
                  <div className="absolute top-2 right-2 bg-primary-green text-white px-2 py-1 rounded-full text-xs font-medium">
                    Vérifié
                  </div>
                )}
              </div>

              {/* Contenu */}
              <div>
                <h3 className="text-lg font-semibold text-neutral-900 mb-1 group-hover:text-primary-orange transition-colors">
                  {service.title}
                </h3>
                <p className="text-sm text-neutral-600 mb-2">
                  par {service.provider}
                </p>
                <p className="text-sm text-neutral-700 mb-3">
                  {service.description}
                </p>

                {/* Rating et avis */}
                <div className="flex items-center mb-3">
                  <div className="flex items-center">
                    <StarIcon className="w-4 h-4 text-secondary-gold fill-current" />
                    <span className="text-sm font-medium text-neutral-900 ml-1">
                      {service.rating}
                    </span>
                  </div>
                  <span className="text-sm text-neutral-500 ml-2">
                    ({service.reviews} avis)
                  </span>
                </div>

                {/* Infos pratiques */}
                <div className="flex items-center justify-between text-sm text-neutral-600 mb-4">
                  <div className="flex items-center">
                    <ClockIcon className="w-4 h-4 mr-1" />
                    {service.responseTime}
                  </div>
                  <div className="flex items-center">
                    <MapPinIcon className="w-4 h-4 mr-1" />
                    {service.location.split(',')[0]}
                  </div>
                </div>

                {/* Prix et action */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center">
                    <CurrencyDollarIcon className="w-4 h-4 text-primary-green mr-1" />
                    <span className="text-lg font-bold text-primary-green">
                      {service.price} {service.currency}
                    </span>
                  </div>
                  <button className="btn-primary text-sm px-4 py-2">
                    Réserver
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Pagination */}
        <div className="flex justify-center mt-12">
          <nav className="flex space-x-2">
            <button className="px-3 py-2 border border-neutral-300 rounded-lg text-neutral-600 hover:bg-neutral-100">
              Précédent
            </button>
            <button className="px-3 py-2 bg-primary-orange text-white rounded-lg">
              1
            </button>
            <button className="px-3 py-2 border border-neutral-300 rounded-lg text-neutral-600 hover:bg-neutral-100">
              2
            </button>
            <button className="px-3 py-2 border border-neutral-300 rounded-lg text-neutral-600 hover:bg-neutral-100">
              3
            </button>
            <button className="px-3 py-2 border border-neutral-300 rounded-lg text-neutral-600 hover:bg-neutral-100">
              Suivant
            </button>
          </nav>
        </div>
      </div>
    </div>
  )
}

export default ServicesPage
