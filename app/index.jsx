import { View } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useForm } from '../context/FormContext'
import EmptyLeadsList from '../components/EmptyLeadsList'

export default function IndexScreen() {
  const { handleNewLead } = useForm()
  const insets = useSafeAreaInsets()

  return (
    <View style={{ flex: 1, backgroundColor: '#e5e7eb', paddingTop: insets.top, paddingBottom: insets.bottom }}>
      <EmptyLeadsList onNewLead={handleNewLead} />
    </View>
  )
}
