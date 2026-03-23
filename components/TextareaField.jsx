import { View, Text, TextInput } from 'react-native'

export default function TextareaField({
  label,
  placeholder,
  required = false,
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
        className="bg-white border border-[#d0d5dd] rounded-lg flex flex-row items-start px-3.5 py-3 w-full"
        style={{
          minHeight: 66,
          shadowColor: '#101828', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 2, elevation: 1,
        }}
      >
        <TextInput
          placeholder={placeholder}
          placeholderTextColor="#667085"
          value={value}
          onChangeText={onChangeText}
          multiline
          numberOfLines={2}
          className="flex-1 text-[16px] leading-6 text-[#101828] bg-transparent"
          style={{ textAlignVertical: 'top' }}
        />
      </View>
    </View>
  )
}
