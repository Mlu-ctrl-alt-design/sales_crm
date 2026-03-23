import { View } from 'react-native'
import { router } from 'expo-router'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useForm } from '../../context/FormContext'
import LeadDetails from '../../components/LeadDetails'

export default function LeadDetailsScreen() {
  const { currentLead } = useForm()
  const insets = useSafeAreaInsets()

  return (
    <View style={{ flex: 1, backgroundColor: '#f5f5f5', paddingTop: insets.top, paddingBottom: insets.bottom }}>
      <LeadDetails
        lead={currentLead}
        onBack={() => router.push('/')}
      />
    </View>
  )
}
