import { createContext, useContext, useState } from 'react'
import { router } from 'expo-router'
import { createLead } from '../api/erpnext'

const INIT_COMPANY = {
  customer: '', telephone: '', company: '',
  email: '', physicalAddress: '', postalCode: '',
  website: '', contactNotes: '',
}

const INIT_PRODUCT = { startTrail: '', prospectValue: '', businessUnit: '' }

const FormContext = createContext(null)

export function FormProvider({ children }) {
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
      // destination can be a string or a function(leadData) => string
      const dest = typeof destination === 'function' ? destination(result.data) : destination
      router.push(dest)
    } else {
      setApiState({ loading: false, error: result.error })
    }
  }

  function handleNewLead() {
    setCompanyForm(INIT_COMPANY)
    setProductForm(INIT_PRODUCT)
    setCurrentLead(null)
    setApiState({ loading: false, error: null })
    router.push('/capture/company')
  }

  function clearError() {
    setApiState(prev => ({ ...prev, error: null }))
  }

  return (
    <FormContext.Provider value={{
      companyForm, productForm, currentLead, apiState,
      handleCompanyChange, handleProductChange,
      handleCreateLead, handleNewLead, clearError,
    }}>
      {children}
    </FormContext.Provider>
  )
}

export function useForm() {
  const ctx = useContext(FormContext)
  if (!ctx) throw new Error('useForm must be used inside FormProvider')
  return ctx
}
