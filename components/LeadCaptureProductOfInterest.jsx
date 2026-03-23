import { View, Text, ScrollView, TouchableOpacity } from 'react-native'
import Svg, { Path } from 'react-native-svg'
import InputField from './InputField'
import SelectField from './SelectField'
import ProgressSteps from './ProgressSteps'

export default function LeadCaptureProductOfInterest({
  onBack,
  formData,
  onChange,
  onSaveAndContinue,
  onSaveAndClose,
  loading = false,
  error = null,
}) {
  const canContinue =
    formData.startTrail !== '' &&
    formData.prospectValue.trim() !== '' &&
    formData.businessUnit.trim() !== ''

  return (
    <View className="bg-white flex flex-col items-center rounded-[24px] w-full flex-1" style={{ overflow: 'hidden' }}>
      {/* Top App Bar */}
      <View className="bg-white flex flex-row gap-1 items-center px-1 py-2 w-full">
        <TouchableOpacity
          onPress={onBack}
          className="flex items-center justify-center w-12 h-12"
        >
          <Svg width={24} height={24} viewBox="0 0 24 24" fill="none">
            <Path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z" fill="#1a1c18" />
          </Svg>
        </TouchableOpacity>
        <Text className="flex-1 font-medium text-[20px] leading-[30px] text-[#1a1c18]">
          Capturing Lead
        </Text>
      </View>

      {/* Scrollable Body */}
      <ScrollView className="flex-1 w-full" contentContainerStyle={{ paddingHorizontal: 16, flexGrow: 1 }}>
        <View className="bg-white flex flex-col flex-1 gap-2.5 pb-4 pt-4 px-3 w-full">

          {/* Page Header */}
          <View className="flex flex-col gap-5 w-full">
            <View className="flex flex-col gap-1 w-full">
              <Text className="font-semibold text-[18px] leading-7 text-[#101828] w-full">
                Product of Interest
              </Text>
              <Text className="font-normal text-[14px] leading-5 text-[#475467] w-full">
                Please fill in lead details.
              </Text>
            </View>
            <View style={{ height: 1, backgroundColor: '#e4e7ec', width: '100%' }} />
          </View>

          {/* Progress Steps */}
          <View className="flex items-center justify-center w-full py-1">
            <ProgressSteps steps={['complete', 'complete', 'current']} />
          </View>

          {/* Form Fields */}
          <View className="flex flex-col gap-4 w-full">
            <SelectField
              label="Start Trail"
              placeholder="Choose an option"
              value={formData.startTrail}
              onChange={v => onChange('startTrail', v)}
              options={['30 days', '60 days', '90 days', '120 days']}
            />
            <InputField
              label="Prospect Value"
              placeholder="R0.00"
              value={formData.prospectValue}
              onChangeText={v => onChange('prospectValue', v)}
            />
            <InputField
              label="Business Unit"
              placeholder="Business Unit"
              value={formData.businessUnit}
              onChangeText={v => onChange('businessUnit', v)}
            />
          </View>

          <View className="flex-1" />

          {/* Error */}
          {error && (
            <Text className="text-sm text-red-600 text-center px-2">
              {error}
            </Text>
          )}

          {/* Action Buttons */}
          <View className="flex flex-col gap-2.5 w-full pb-4">
            <TouchableOpacity
              disabled={!canContinue || loading}
              onPress={onSaveAndContinue}
              className="rounded-lg flex flex-row items-center justify-center gap-1.5 px-[18px] py-3 w-full"
              style={{
                backgroundColor: canContinue && !loading ? '#0086c9' : '#f2f4f7',
                borderWidth: 1,
                borderColor: canContinue && !loading ? '#0086c9' : '#e4e7ec',
                shadowColor: '#101828', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 2, elevation: 1,
              }}
            >
              <Text
                className="font-semibold text-[16px] leading-6"
                style={{ color: canContinue && !loading ? 'white' : '#98a2b3' }}
              >
                {loading ? 'Saving…' : 'Save & Continue'}
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              disabled={loading}
              onPress={onSaveAndClose}
              className="bg-white rounded-lg flex flex-row items-center justify-center gap-1.5 px-[18px] py-3 w-full"
              style={{
                borderWidth: 1, borderColor: '#7cd4fd',
                shadowColor: '#101828', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 2, elevation: 1,
                opacity: loading ? 0.6 : 1,
              }}
            >
              <Text className="font-semibold text-[16px] leading-6 text-[#026aa2]">
                {loading ? 'Saving…' : 'Save & Close'}
              </Text>
            </TouchableOpacity>
          </View>

        </View>
      </ScrollView>
    </View>
  )
}
