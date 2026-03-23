import { View } from 'react-native'
import { router } from 'expo-router'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useForm } from '../../context/FormContext'
import LeadCaptureProductOfInterest from '../../components/LeadCaptureProductOfInterest'

export default function ProductScreen() {
  const { productForm, apiState, handleProductChange, handleCreateLead } = useForm()
  const insets = useSafeAreaInsets()

  return (
    <View style={{ flex: 1, backgroundColor: '#e5e7eb', paddingTop: insets.top, paddingBottom: insets.bottom }}>
      <LeadCaptureProductOfInterest
        formData={productForm}
        onChange={handleProductChange}
        onBack={() => router.back()}
        onSaveAndContinue={() => handleCreateLead(productForm, (lead) => `/lead/${lead.name}`)}
        onSaveAndClose={() => handleCreateLead(productForm, '/')}
        loading={apiState.loading}
        error={apiState.error}
      />
    </View>
  )
}
