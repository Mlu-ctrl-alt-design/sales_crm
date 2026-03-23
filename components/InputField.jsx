import { View, Text, TextInput } from 'react-native'

export default function InputField({
  label,
  placeholder,
  required = false,
  keyboardType = 'default',
  value,
  onChangeText,
}) {
  return (
    <View className="flex flex-col gap-1.5 w-full">
      <View className="flex flex-row gap-0.5 items-center">
        <Text className="font-medium text-[14px] leading-5 text-[#344054]">
          {label}
        </Text>
        {required && (
          <Text className="font-medium text-[14px] leading-5 text-[#0086c9]">*</Text>
        )}
      </View>
      <View
        className="bg-white border border-[#d0d5dd] rounded-lg flex flex-row items-center gap-2 px-3.5 py-2.5 w-full"
        style={{ shadowColor: '#101828', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 2, elevation: 1 }}
      >
        <TextInput
          keyboardType={keyboardType}
          placeholder={placeholder}
          placeholderTextColor="#667085"
          value={value}
          onChangeText={onChangeText}
          className="flex-1 text-[16px] leading-6 text-[#101828] bg-transparent"
          style={{ fontFamily: undefined }}
        />
      </View>
    </View>
  )
}
