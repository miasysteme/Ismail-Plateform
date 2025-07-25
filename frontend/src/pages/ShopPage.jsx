import React from 'react'
import { ShoppingBagIcon } from '@heroicons/react/24/outline'

const ShopPage = () => {
  return (
    <div className="min-h-screen bg-neutral-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="text-center">
          <div className="w-16 h-16 bg-primary-green rounded-lg flex items-center justify-center mx-auto mb-6">
            <ShoppingBagIcon className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-4xl font-bold text-neutral-900 mb-4">
            ISMAIL Shop
          </h1>
          <p className="text-xl text-neutral-600 mb-8 max-w-2xl mx-auto">
            Marketplace pour acheter et vendre vos produits en ligne. 
            E-commerce sécurisé avec livraison dans toute l'Afrique de l'Ouest.
          </p>
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6 max-w-md mx-auto">
            <p className="text-yellow-800 font-medium">
              🚧 Module en développement
            </p>
            <p className="text-yellow-700 text-sm mt-2">
              Cette fonctionnalité sera bientôt disponible. Restez connecté !
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default ShopPage
