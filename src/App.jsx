import { useState } from 'react'
import LeadDetails from './components/LeadDetails'
import LeadCaptureCompanyDetails from './components/LeadCaptureCompanyDetails'

const SCREENS = {
  LEAD_DETAILS: 'lead_details',
  LEAD_CAPTURE: 'lead_capture',
}

function App() {
  const [screen, setScreen] = useState(SCREENS.LEAD_CAPTURE)

  return (
    <div className="min-h-screen bg-gray-200 flex flex-col items-center justify-start p-4">
      {/* Screen switcher */}
      <div className="flex gap-2 mb-4">
        <button
          onClick={() => setScreen(SCREENS.LEAD_CAPTURE)}
          className={`px-3 py-1.5 rounded-lg text-sm font-medium border ${
            screen === SCREENS.LEAD_CAPTURE
              ? 'bg-white border-[#0ba5ec] text-[#026aa2]'
              : 'bg-white border-gray-300 text-gray-600'
          }`}
        >
          Lead Capture
        </button>
        <button
          onClick={() => setScreen(SCREENS.LEAD_DETAILS)}
          className={`px-3 py-1.5 rounded-lg text-sm font-medium border ${
            screen === SCREENS.LEAD_DETAILS
              ? 'bg-white border-[#0ba5ec] text-[#026aa2]'
              : 'bg-white border-gray-300 text-gray-600'
          }`}
        >
          Lead Details
        </button>
      </div>

      <div className="w-[390px]">
        {screen === SCREENS.LEAD_CAPTURE && (
          <LeadCaptureCompanyDetails onBack={() => setScreen(SCREENS.LEAD_DETAILS)} />
        )}
        {screen === SCREENS.LEAD_DETAILS && (
          <LeadDetails />
        )}
      </div>
    </div>
  )
}

export default App
