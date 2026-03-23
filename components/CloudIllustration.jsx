import { View } from 'react-native'
import Svg, { Circle, Path } from 'react-native-svg'
import { BlurView } from 'expo-blur'

export default function CloudIllustration() {
  return (
    <View style={{ width: 220, height: 160 }}>
      {/* Large background circle */}
      <Svg style={{ position: 'absolute', left: 30, top: 0 }} width={160} height={160} viewBox="0 0 160 160" fill="none">
        <Circle cx="80" cy="80" r="80" fill="#f2f4f7" />
      </Svg>

      {/* Decorative small circles */}
      <Svg style={{ position: 'absolute', left: 18, top: 12 }} width={16} height={16} viewBox="0 0 16 16" fill="none">
        <Circle cx="8" cy="8" r="8" fill="#e4e7ec" />
      </Svg>
      <Svg style={{ position: 'absolute', left: 192, top: 120 }} width={12} height={12} viewBox="0 0 12 12" fill="none">
        <Circle cx="6" cy="6" r="6" fill="#e4e7ec" />
      </Svg>
      <Svg style={{ position: 'absolute', left: 15, top: 128 }} width={20} height={20} viewBox="0 0 20 20" fill="none">
        <Circle cx="10" cy="10" r="10" fill="#d0d5dd" />
      </Svg>
      <Svg style={{ position: 'absolute', left: 200, top: 36 }} width={20} height={20} viewBox="0 0 20 20" fill="none">
        <Circle cx="10" cy="10" r="10" fill="#d0d5dd" />
      </Svg>
      <Svg style={{ position: 'absolute', left: 184, top: 4 }} width={14} height={14} viewBox="0 0 14 14" fill="none">
        <Circle cx="7" cy="7" r="7" fill="#e4e7ec" />
      </Svg>

      {/* Cloud shape */}
      <Svg style={{ position: 'absolute', left: 24, top: 16 }} width={174} height={100} viewBox="0 0 174 100" fill="none">
        {/* Main cloud body — drop-shadow not supported in RN SVG, omitted */}
        <Path
          d="M138 70H44C31.3 70 21 59.7 21 47s10.3-23 23-23c.9 0 1.8.1 2.7.2C50.4 13.4 62 5 75.5 5c16.8 0 30.5 13.2 31 30 .8-.1 1.7-.1 2.5-.1 14.4 0 26 11.6 26 26 0 5-.7 9-2 9z"
          fill="white"
          fillOpacity={0.9}
        />
        {/* Second cloud layer for depth */}
        <Path
          d="M155 85H55C40.1 85 28 72.9 28 58c0-12.1 8.1-22.3 19.2-25.5C51.9 22.2 63.6 14 77 14c14.5 0 26.8 9.5 30.8 22.7 1.4-.3 2.8-.4 4.2-.4 13.8 0 25 11.2 25 25 0 1.4-.1 2.7-.3 4 9.3 2.2 16.3 10.5 16.3 20.4V86c-1.2-.7-2.5-1-4-1z"
          fill="white"
          fillOpacity={0.5}
        />
      </Svg>

      {/* Search badge — blurred dark circle with magnify icon */}
      <View
        style={{
          position: 'absolute', left: 82, top: 84,
          width: 56, height: 56, borderRadius: 28,
          overflow: 'hidden',
        }}
      >
        <BlurView
          intensity={20}
          tint="dark"
          style={{
            position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
          }}
        />
        <View
          style={{
            position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
            backgroundColor: 'rgba(52,64,84,0.4)',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <Svg width={28} height={28} viewBox="0 0 28 28" fill="none">
            <Circle cx="13" cy="13" r="8" stroke="white" strokeWidth="2.5" />
            <Path d="M19 19l4 4" stroke="white" strokeWidth="2.5" strokeLinecap="round" />
          </Svg>
        </View>
      </View>
    </View>
  )
}
