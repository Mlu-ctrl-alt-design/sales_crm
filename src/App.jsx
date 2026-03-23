import { useState } from 'react'
import { createLead } from './api/erpnext'
import EmptyLeadsList from './components/EmptyLeadsList'
import LeadCaptureCompanyDetails from './components/LeadCaptureCompanyDetails'
import LeadCaptureProductOfInterest from './components/LeadCaptureProductOfInterest'
import LeadDetails from './components/LeadDetails'

const SCREENS = {
  EMPTY_LEADS:            'empty_leads',
  LEAD_CAPTURE:           'lead_capture',
  LEAD_CAPTURE_PRODUCT:   'lead_capture_product',
  LEAD_DETAILS:           'lead_details',
}

const INIT_COMPANY = {
  customer: '', telephone: '', company: '',
  email: '', physicalAddress: '', postalCode: '',
  website: '', contactNotes: '',
}

const INIT_PRODUCT = { startTrail: '', prospectValue: '', businessUnit: '' }

function App() {
  const [screen, setScreen]           = useState(SCREENS.EMPTY_LEADS)
  const [companyForm, setCompanyForm] = useState(INIT_COMPANY)
  const [productForm, setProductForm] = useState(INIT_PRODUCT)
  const [currentLead, setCurrentLead] = useState(null)
  const [apiState, setApiState]       = useState({ loading: false, error: null })

  function handleCompanyChange(field, value) {
    setCompanyForm(prev => ({ ...prev, [field]: value }))
  }

  function handleProductChange(field, value) {
    setProductForm(prev => ({ ...prev, [field]: value }))
  }

  async function handleCreateLead(productData, destination) {
    setApiState({ loading: true, error: null })
    const result = await createLead(companyForm, productData)
    if (result.success) {
      setCurrentLead(result.data)
      setApiState({ loading: false, error: null })
      setScreen(destination)
    } else {
      setApiState({ loading: false, error: result.error })
    }
  }

  function handleNewLead() {
    setCompanyForm(INIT_COMPANY)
    setProductForm(INIT_PRODUCT)
    setCurrentLead(null)
    setApiState({ loading: false, error: null })
    setScreen(SCREENS.LEAD_CAPTURE)
  }

  const NAV = [
    { key: SCREENS.EMPTY_LEADS,          label: 'Empty Leads' },
    { key: SCREENS.LEAD_CAPTURE,         label: 'Company Details' },
    { key: SCREENS.LEAD_CAPTURE_PRODUCT, label: 'Product of Interest' },
    { key: SCREENS.LEAD_DETAILS,         label: 'Lead Details' },
  ]

  return (
    <div className="min-h-screen bg-gray-200 flex flex-col items-center justify-start p-4">
      {/* Dev nav */}
      <div className="flex flex-wrap gap-2 mb-4 justify-center">
        {NAV.map(({ key, label }) => (
          <button
            key={key}
            onClick={() => setScreen(key)}
            className={`px-3 py-1.5 rounded-lg text-sm font-medium border ${
              screen === key
                ? 'bg-white border-[#0ba5ec] text-[#026aa2]'
                : 'bg-white border-gray-300 text-gray-600'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      <div className="w-[390px]">
        {screen === SCREENS.EMPTY_LEADS && (
          <EmptyLeadsList onNewLead={handleNewLead} />
        )}

        {screen === SCREENS.LEAD_CAPTURE && (
          <LeadCaptureCompanyDetails
            formData={companyForm}
            onChange={handleCompanyChange}
            onBack={() => setScreen(SCREENS.EMPTY_LEADS)}
            onSaveAndContinue={() => {
              setApiState({ loading: false, error: null })
              setScreen(SCREENS.LEAD_CAPTURE_PRODUCT)
            }}
            onSaveAndClose={() => handleCreateLead(productForm, SCREENS.EMPTY_LEADS)}
            loading={apiState.loading}
            error={apiState.error}
          />
        )}

        {screen === SCREENS.LEAD_CAPTURE_PRODUCT && (
          <LeadCaptureProductOfInterest
            formData={productForm}
            onChange={handleProductChange}
            onBack={() => setScreen(SCREENS.LEAD_CAPTURE)}
            onSaveAndContinue={() => handleCreateLead(productForm, SCREENS.LEAD_DETAILS)}
            onSaveAndClose={() => handleCreateLead(productForm, SCREENS.EMPTY_LEADS)}
            loading={apiState.loading}
            error={apiState.error}
          />
        )}

        {screen === SCREENS.LEAD_DETAILS && (
          <LeadDetails
            lead={currentLead}
            onBack={() => setScreen(SCREENS.EMPTY_LEADS)}
          />
        )}
      </div>
    </div>
  )
}

export default App
