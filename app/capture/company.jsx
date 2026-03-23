import { View } from 'react-native'
import { router } from 'expo-router'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useForm } from '../../context/FormContext'
import LeadCaptureCompanyDetails from '../../components/LeadCaptureCompanyDetails'

export default function CompanyScreen() {
  const { companyForm, productForm, apiState, handleCompanyChange, handleCreateLead, clearError } = useForm()
  const insets = useSafeAreaInsets()

  return (
    <View style={{ flex: 1, backgroundColor: '#e5e7eb', paddingTop: insets.top, paddingBottom: insets.bottom }}>
      <LeadCaptureCompanyDetails
        formData={companyForm}
        onChange={handleCompanyChange}
        onBack={() => router.back()}
        onSaveAndContinue={() => {
          clearError()
          router.push('/capture/product')
        }}
        onSaveAndClose={() => handleCreateLead(productForm, '/')}
        loading={apiState.loading}
        error={apiState.error}
      />
    </View>
  )
}
