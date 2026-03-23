import { View, Text, TouchableOpacity, ScrollView } from 'react-native'
import Svg, { Path } from 'react-native-svg'
import CloudIllustration from './CloudIllustration'

export default function EmptyLeadsList({ onNewLead }) {
  return (
    <View className="bg-white flex flex-col items-center rounded-[24px] w-full flex-1" style={{ overflow: 'hidden' }}>
      {/* Top App Bar */}
      <View className="bg-white flex flex-row gap-1 items-center px-1 py-2 w-full">
        <TouchableOpacity className="flex items-center justify-center w-12 h-12">
          <Svg width={24} height={24} viewBox="0 0 24 24" fill="none">
            <Path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z" fill="#1a1c18" />
          </Svg>
        </TouchableOpacity>
        <Text className="flex-1 font-medium text-[20px] leading-[30px] text-[#1a1c18]">
          Sales
        </Text>
      </View>

      {/* Body */}
      <ScrollView
        className="flex-1 w-full bg-[#f5f5f5]"
        contentContainerStyle={{ flexGrow: 1 }}
      >
        <View className="flex-1 items-center justify-center px-4 pt-6 pb-6">
          <View className="flex-1 items-center justify-center w-full">
            <View className="flex flex-col items-center gap-16 w-full">
              {/* Illustration + text */}
              <View className="flex flex-col items-center gap-6 w-full">
                <CloudIllustration />
                <View className="flex flex-col items-center gap-2 w-full" style={{ maxWidth: 352 }}>
                  <Text className="font-semibold text-[20px] leading-[30px] text-[#101828] text-center w-full">
                    No Leads Available
                  </Text>
                  <Text className="font-normal text-[16px] leading-6 text-[#475467] text-center w-full">
                    You do not have any leads created, click New Lead to create your first lead.
                  </Text>
                </View>
              </View>

              {/* CTA */}
              <TouchableOpacity
                onPress={onNewLead}
                className="bg-[#0086c9] rounded-lg flex flex-row items-center gap-1.5 justify-center px-4 py-2.5"
                style={{
                  borderWidth: 2, borderColor: 'rgba(255,255,255,0.12)',
                  shadowColor: '#101828', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 2, elevation: 2,
                }}
              >
                <Svg width={20} height={20} viewBox="0 0 20 20" fill="none">
                  <Path d="M10 4v12M4 10h12" stroke="white" strokeWidth="1.67" strokeLinecap="round" />
                </Svg>
                <Text className="font-semibold text-[16px] leading-6 text-white">
                  New Lead
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </ScrollView>
    </View>
  )
}
