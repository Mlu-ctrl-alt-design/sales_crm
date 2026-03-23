import { View } from 'react-native'
import Svg, { Circle, Path } from 'react-native-svg'

function StepIcon({ status = 'incomplete' }) {
  if (status === 'complete') {
    return (
      <View className="relative rounded-full overflow-hidden" style={{ width: 24, height: 24, backgroundColor: '#f0f9ff' }}>
        <Svg width={24} height={24} viewBox="0 0 24 24" fill="none" style={{ position: 'absolute', top: 0, left: 0 }}>
          <Circle cx="12" cy="12" r="12" fill="#0086c9" />
          <Path d="M7 12.5l3.5 3.5 6.5-7" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        </Svg>
      </View>
    )
  }

  if (status === 'current') {
    return (
      <View
        style={{
          width: 24, height: 24, borderRadius: 12,
          backgroundColor: '#f0f9ff',
          shadowColor: '#0ba5ec',
          shadowOffset: { width: 0, height: 0 },
          shadowOpacity: 1,
          shadowRadius: 0,
          // Ring approximated with border on a wrapper
        }}
      >
        <View
          style={{
            position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
            borderRadius: 12,
            backgroundColor: '#0086c9',
            alignItems: 'center',
            justifyContent: 'center',
            borderWidth: 2,
            borderColor: 'white',
          }}
        >
          <View style={{ width: 8, height: 8, borderRadius: 4, backgroundColor: 'white' }} />
        </View>
      </View>
    )
  }

  return (
    <View
      className="items-center justify-center"
      style={{ width: 24, height: 24, borderRadius: 12, backgroundColor: '#f9fafb', borderWidth: 1.5, borderColor: '#e4e7ec' }}
    >
      <View style={{ width: 8, height: 8, borderRadius: 4, backgroundColor: '#d0d5dd' }} />
    </View>
  )
}

export default function ProgressSteps({ steps = ['current', 'incomplete', 'incomplete'] }) {
  return (
    <View className="flex flex-row items-center justify-center w-full">
      {steps.map((status, i) => (
        <View key={i} className="flex flex-row items-center">
          <StepIcon status={status} />
          {i < steps.length - 1 && (
            <View style={{ height: 2, width: 48, backgroundColor: '#d9d9d9' }} />
          )}
        </View>
      ))}
    </View>
  )
}
