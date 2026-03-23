import { useState } from 'react'
import { View, Text, ScrollView, TouchableOpacity } from 'react-native'
import Svg, { Path } from 'react-native-svg'

function DetailRow({ label, value }) {
  return (
    <View className="flex flex-col gap-1 w-full">
      <Text className="font-semibold text-[16px] leading-6 text-[#101828]">{label}</Text>
      <Text className="font-normal text-[14px] leading-5 text-[#475467]">{value || '—'}</Text>
    </View>
  )
}

export default function LeadDetails({ lead, onBack }) {
  const [activeTab, setActiveTab] = useState('lead_details')

  const companyFields = [
    { label: 'Company',          value: lead?.company_name },
    { label: 'Email',            value: lead?.email_id },
    { label: 'Phone',            value: lead?.phone },
    { label: 'Website',          value: lead?.website },
    { label: 'Physical Address', value: lead?.custom_physical_address },
    { label: 'Postal Code',      value: lead?.custom_postal_code },
    { label: 'Contact Notes',    value: lead?.custom_contact_notes },
  ]

  const leadFields = [
    { label: 'Lead Name',      value: lead?.lead_name },
    { label: 'Start Trail',    value: lead?.custom_start_trail },
    { label: 'Prospect Value', value: lead?.custom_prospect_value },
    { label: 'Business Unit',  value: lead?.custom_business_unit },
    { label: 'Lead ID',        value: lead?.name },
    { label: 'Status',         value: lead?.status },
  ]

  const activeFields = activeTab === 'company_details' ? companyFields : leadFields

  return (
    <View className="bg-[#f5f5f5] flex flex-col items-center rounded-[24px] w-full flex-1" style={{ overflow: 'hidden' }}>
      {/* Top App Bar */}
      <View className="bg-white flex flex-row gap-1 items-center px-1 py-2 w-full">
        <TouchableOpacity onPress={onBack} className="flex items-center justify-center w-12 h-12">
          <Svg width={24} height={24} viewBox="0 0 24 24" fill="none">
            <Path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z" fill="#1a1c18" />
          </Svg>
        </TouchableOpacity>
        <Text className="flex-1 font-medium text-[20px] leading-[30px] text-[#1a1c18]">
          Lead Details
        </Text>
      </View>

      {/* Body */}
      <ScrollView className="flex-1 w-full" contentContainerStyle={{ paddingTop: 24, paddingBottom: 12 }}>
        <View className="flex flex-col gap-2 items-start px-4 w-full">

          {/* Contact Card */}
          <View
            className="bg-[#f0f9ff] rounded-2xl flex flex-col gap-0 items-center p-5 w-full"
            style={{ borderWidth: 1, borderColor: '#0ba5ec' }}
          >
            <View className="flex flex-col gap-4 items-start w-full">
              <View className="flex flex-col gap-3 items-start w-full">
                <View className="flex flex-col gap-1.5 items-start w-full">
                  <Text className="font-semibold text-[18px] leading-7 text-[#101828] w-full">
                    {lead?.lead_name || lead?.company_name || 'New Lead'}
                  </Text>
                  <View className="flex flex-col gap-0 w-full">
                    <View className="flex flex-row gap-2 items-center w-full" style={{ height: 32 }}>
                      <View className="flex flex-1 flex-row gap-2.5 items-center">
                        <Svg width={18} height={18} viewBox="0 0 18 18" fill="none">
                          <Path d="M1.5 4.5A1.5 1.5 0 013 3h12a1.5 1.5 0 011.5 1.5v9A1.5 1.5 0 0115 15H3a1.5 1.5 0 01-1.5-1.5v-9zm1.5 0v.621l6 3.75 6-3.75V4.5H3zm12 2.379l-5.553 3.47a.75.75 0 01-.794 0L3 6.879V13.5h12V6.879z" fill="#475467" />
                        </Svg>
                        <Text className="font-normal text-[12px] leading-[18px] text-[#475467]" numberOfLines={1}>
                          {lead?.email_id || '—'}
                        </Text>
                      </View>
                      <View className="flex flex-1 flex-row gap-2.5 items-center">
                        <Svg width={18} height={18} viewBox="0 0 18 18" fill="none">
                          <Path d="M6.63 4.32C6.44 3.84 5.89 3 5.28 3 4.18 3 3 4.16 3 5.26c0 .7.3 1.39.73 2.1.65 1.06 1.66 2.16 2.78 3.14 1.12.98 2.4 1.85 3.54 2.38.77.36 1.55.62 2.2.62 1.1 0 2.26-1.18 2.26-2.28 0-.6-.82-1.14-1.32-1.35l-1.04-.47c-.5-.22-.97-.02-1.18.22l-.46.54c-.24.27-.63.27-.63.27s-1.75-.63-3.05-2.4c0 0-.13-.37.07-.65l.49-.61c.2-.27.35-.76.1-1.26l-.59-1.18z" fill="#475467" />
                        </Svg>
                        <Text className="font-normal text-[12px] leading-[18px] text-[#475467]" numberOfLines={1}>
                          {lead?.phone || '—'}
                        </Text>
                      </View>
                    </View>
                    <View className="flex flex-row gap-2 items-center w-full" style={{ height: 32 }}>
                      <View className="flex flex-1 flex-row gap-2.5 items-center">
                        <Svg width={18} height={18} viewBox="0 0 18 18" fill="none">
                          <Path d="M3 15.75V3.75A.75.75 0 013.75 3h10.5a.75.75 0 01.75.75V15.75M3 15.75H1.5M3 15.75h3M16.5 15.75H15M16.5 15.75H15M6 15.75v-3.75h6v3.75M6 15.75h6M6.75 6H7.5M10.5 6h.75M6.75 9H7.5M10.5 9h.75" stroke="#475467" strokeWidth="1.125" strokeLinecap="round" strokeLinejoin="round" />
                        </Svg>
                        <Text className="font-normal text-[12px] leading-[18px] text-[#475467]" numberOfLines={1}>
                          {lead?.company_name || '—'}
                        </Text>
                      </View>
                    </View>
                  </View>
                </View>
              </View>
            </View>
          </View>

          {/* Card with Tabs + Details */}
          <View className="flex flex-col w-full rounded-2xl" style={{ overflow: 'hidden' }}>
            {/* Tab Bar */}
            <View className="bg-white flex flex-col gap-0 items-center py-5 w-full">
              <View className="flex flex-col gap-4 items-center px-5 w-full">
                <View className="flex flex-col gap-4 items-center w-full" style={{ maxWidth: 360 }}>
                  <View
                    className="flex flex-row gap-0.5 items-center w-full px-0.5 py-0.5 rounded-lg"
                    style={{ backgroundColor: '#f9fafb', borderWidth: 1, borderColor: '#e4e7ec' }}
                  >
                    <TouchableOpacity
                      onPress={() => setActiveTab('company_details')}
                      className="flex flex-1 flex-row gap-2 items-center justify-center px-3 py-2 rounded-lg"
                      style={activeTab === 'company_details' ? {
                        backgroundColor: 'white',
                        borderWidth: 1, borderColor: '#d0d5dd',
                        shadowColor: '#101828', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 2, elevation: 1,
                        height: 36,
                      } : { height: 36 }}
                    >
                      <Text
                        className="font-semibold text-[14px] leading-5"
                        style={{ color: activeTab === 'company_details' ? '#344054' : '#667085' }}
                        numberOfLines={1}
                      >
                        Company Details
                      </Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                      onPress={() => setActiveTab('lead_details')}
                      className="flex flex-1 flex-row gap-2 items-center justify-center px-3 py-2 rounded-lg"
                      style={activeTab === 'lead_details' ? {
                        backgroundColor: 'white',
                        borderWidth: 1, borderColor: '#d0d5dd',
                        shadowColor: '#101828', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 2, elevation: 1,
                        height: 36,
                      } : { height: 36 }}
                    >
                      <Text
                        className="font-semibold text-[14px] leading-5"
                        style={{ color: activeTab === 'lead_details' ? '#344054' : '#667085' }}
                        numberOfLines={1}
                      >
                        Lead Details
                      </Text>
                    </TouchableOpacity>
                  </View>
                </View>
              </View>
            </View>

            {/* Details Section */}
            <View className="bg-white flex flex-col gap-4 pb-8 pt-4 px-1 w-full" style={{ borderBottomLeftRadius: 16, borderBottomRightRadius: 16 }}>
              {lead ? (
                <>
                  <View className="px-4">
                    <Text className="text-[#101828]">
                      <Text className="font-semibold text-[16px] leading-6">Lead ID: </Text>
                      <Text className="font-normal text-[14px] leading-5 text-[#475467]">{lead.name || '—'}</Text>
                    </Text>
                  </View>
                  <View className="flex flex-col gap-5 px-4 w-full">
                    {activeFields.map(({ label, value }) => (
                      <DetailRow key={label} label={label} value={value} />
                    ))}
                  </View>
                </>
              ) : (
                <View className="flex flex-col items-center justify-center py-12 px-4 gap-2">
                  <Text className="font-semibold text-[16px] text-[#101828]">No lead selected</Text>
                  <Text className="font-normal text-[14px] text-[#475467] text-center">
                    Create a lead using the New Lead flow to see details here.
                  </Text>
                </View>
              )}
            </View>
          </View>

        </View>
      </ScrollView>
    </View>
  )
}
