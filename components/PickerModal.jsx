import { useState } from 'react'
import { View, Text, Modal, FlatList, Pressable, TouchableOpacity } from 'react-native'
import Svg, { Path } from 'react-native-svg'

export default function PickerModal({
  label,
  placeholder,
  value,
  options = [],
  onSelect,
}) {
  const [visible, setVisible] = useState(false)

  function handleSelect(opt) {
    onSelect(opt)
    setVisible(false)
  }

  return (
    <View className="flex flex-col gap-1.5 w-full">
      <Text className="font-medium text-[14px] leading-5 text-[#344054]">
        {label}
      </Text>

      <TouchableOpacity
        onPress={() => setVisible(true)}
        activeOpacity={0.7}
        className="bg-white border border-[#d0d5dd] rounded-lg flex flex-row items-center gap-2 px-3.5 py-2.5 w-full"
        style={{ shadowColor: '#101828', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 2, elevation: 1 }}
      >
        <Text
          className="flex-1 text-[16px] leading-6"
          style={{ color: value ? '#101828' : '#667085' }}
        >
          {value || placeholder}
        </Text>
        <Svg width={20} height={20} viewBox="0 0 20 20" fill="none">
          <Path d="M5 7.5l5 5 5-5" stroke="#667085" strokeWidth="1.67" strokeLinecap="round" strokeLinejoin="round" />
        </Svg>
      </TouchableOpacity>

      <Modal visible={visible} transparent animationType="fade" onRequestClose={() => setVisible(false)}>
        <Pressable
          className="flex-1 justify-end"
          style={{ backgroundColor: 'rgba(0,0,0,0.4)' }}
          onPress={() => setVisible(false)}
        >
          <Pressable onPress={() => {}} className="bg-white rounded-t-2xl pb-6">
            <View className="flex flex-row items-center justify-between px-5 py-4 border-b border-[#e4e7ec]">
              <Text className="font-semibold text-[16px] text-[#101828]">{label}</Text>
              <TouchableOpacity onPress={() => setVisible(false)}>
                <Text className="text-[14px] text-[#667085]">Cancel</Text>
              </TouchableOpacity>
            </View>
            <FlatList
              data={options}
              keyExtractor={item => item}
              renderItem={({ item }) => (
                <TouchableOpacity
                  onPress={() => handleSelect(item)}
                  className="px-5 py-4 border-b border-[#f2f4f7]"
                >
                  <Text
                    className="text-[16px] leading-6"
                    style={{ color: item === value ? '#0086c9' : '#101828', fontWeight: item === value ? '600' : '400' }}
                  >
                    {item}
                  </Text>
                </TouchableOpacity>
              )}
            />
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  )
}
