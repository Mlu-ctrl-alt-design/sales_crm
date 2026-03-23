import { useState } from 'react'
import LeadDetails from './components/LeadDetails'
import LeadCaptureCompanyDetails from './components/LeadCaptureCompanyDetails'
import EmptyLeadsList from './components/EmptyLeadsList'
import LeadCaptureProductOfInterest from './components/LeadCaptureProductOfInterest'

const SCREENS = {
  EMPTY_LEADS: 'empty_leads',
  LEAD_CAPTURE: 'lead_capture',
  LEAD_CAPTURE_PRODUCT: 'lead_capture_product',
  LEAD_DETAILS: 'lead_details',
}

const NAV = [
  { key: SCREENS.EMPTY_LEADS,        label: 'Empty Leads' },
  { key: SCREENS.LEAD_CAPTURE,       label: 'Lead Capture' },
  { key: SCREENS.LEAD_CAPTURE_PRODUCT, label: 'Product of Interest' },
  { key: SCREENS.LEAD_DETAILS,       label: 'Lead Details' },
]

function App() {
  const [screen, setScreen] = useState(SCREENS.EMPTY_LEADS)

  return (
    <div className="min-h-screen bg-gray-200 flex flex-col items-center justify-start p-4">
      {/* Screen switcher */}
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
          <EmptyLeadsList onNewLead={() => setScreen(SCREENS.LEAD_CAPTURE)} />
        )}
        {screen === SCREENS.LEAD_CAPTURE && (
          <LeadCaptureCompanyDetails onBack={() => setScreen(SCREENS.EMPTY_LEADS)} />
        )}
        {screen === SCREENS.LEAD_CAPTURE_PRODUCT && (
          <LeadCaptureProductOfInterest onBack={() => setScreen(SCREENS.LEAD_CAPTURE)} />
        )}
        {screen === SCREENS.LEAD_DETAILS && (
          <LeadDetails />
        )}
      </div>
    </div>
  )
}

export default App
