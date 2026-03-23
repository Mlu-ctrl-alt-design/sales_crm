import PickerModal from './PickerModal'

// Thin wrapper that matches the web SelectField API:
// value, onChange(newValue), label, placeholder, options
export default function SelectField({ label, placeholder, value, onChange, options = [] }) {
  return (
    <PickerModal
      label={label}
      placeholder={placeholder}
      value={value}
      options={options}
      onSelect={onChange}
    />
  )
}
