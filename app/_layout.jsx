import '../global.css'
import { Stack } from 'expo-router'
import { SafeAreaProvider } from 'react-native-safe-area-context'
import { StatusBar } from 'expo-status-bar'
import { FormProvider } from '../context/FormContext'

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <FormProvider>
        <StatusBar style="dark" />
        <Stack screenOptions={{ headerShown: false }} />
      </FormProvider>
    </SafeAreaProvider>
  )
}
