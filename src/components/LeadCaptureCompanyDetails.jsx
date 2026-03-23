function StepIcon({ status = "incomplete" }) {
  if (status === "complete") {
    return (
      <div className="relative rounded-full size-6 bg-[#f0f9ff] shrink-0 overflow-clip">
        <svg className="absolute inset-0 w-full h-full" viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="12" r="12" fill="#0086c9" />
          <path d="M7 12.5l3.5 3.5 6.5-7" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
    );
  }
  if (status === "current") {
    return (
      <div
        className="relative rounded-full size-6 bg-[#f0f9ff] shrink-0"
        style={{ boxShadow: "0 0 0 2px white, 0 0 0 4px #0ba5ec" }}
      >
        <div className="absolute inset-0 rounded-full bg-[#0086c9] flex items-center justify-center">
          <div className="size-2 rounded-full bg-white" />
        </div>
      </div>
    );
  }
  return (
    <div className="relative rounded-full size-6 bg-[#f9fafb] shrink-0 border-[1.5px] border-[#e4e7ec] flex items-center justify-center">
      <div className="size-2 rounded-full bg-[#d0d5dd]" />
    </div>
  );
}

function ProgressSteps({ steps = ["current", "incomplete", "incomplete"] }) {
  return (
    <div className="flex items-center justify-center w-full">
      {steps.map((status, i) => (
        <div key={i} className="flex items-center">
          <StepIcon status={status} />
          {i < steps.length - 1 && (
            <div className="h-0.5 w-12 bg-[#d9d9d9]" />
          )}
        </div>
      ))}
    </div>
  );
}

function InputField({ label, placeholder, required = false, type = "text", value, onChange }) {
  return (
    <div className="flex flex-col gap-1.5 w-full">
      <div className="flex gap-0.5 items-center">
        <label className="font-['Inter',sans-serif] font-medium text-[14px] leading-5 text-[#344054]">
          {label}
        </label>
        {required && (
          <span className="font-['Inter',sans-serif] font-medium text-[14px] leading-5 text-[#0086c9]">*</span>
        )}
      </div>
      <div className="bg-white border border-[#d0d5dd] rounded-lg shadow-[0px_1px_2px_0px_rgba(16,24,40,0.05)] flex items-center gap-2 px-3.5 py-2.5 w-full">
        <input
          type={type}
          placeholder={placeholder}
          value={value}
          onChange={onChange}
          className="flex-1 font-['Inter',sans-serif] font-normal text-[16px] leading-6 text-[#101828] placeholder-[#667085] bg-transparent outline-none w-full"
        />
      </div>
    </div>
  );
}

function SelectField({ label, placeholder, value, onChange }) {
  return (
    <div className="flex flex-col gap-1.5 w-full">
      <label className="font-['Inter',sans-serif] font-medium text-[14px] leading-5 text-[#344054]">
        {label}
      </label>
      <div className="bg-white border border-[#d0d5dd] rounded-lg shadow-[0px_1px_2px_0px_rgba(16,24,40,0.05)] flex items-center gap-2 px-3.5 py-2.5 w-full relative">
        <select
          value={value}
          onChange={onChange}
          className="flex-1 font-['Inter',sans-serif] font-normal text-[16px] leading-6 bg-transparent outline-none appearance-none w-full text-[#101828]"
          style={{ color: value ? '#101828' : '#667085' }}
        >
          <option value="" disabled>{placeholder}</option>
          <option value="prospect">Prospect</option>
          <option value="customer">Customer</option>
          <option value="partner">Partner</option>
        </select>
        <svg width="20" height="20" viewBox="0 0 20 20" fill="none" className="shrink-0 pointer-events-none">
          <path d="M5 7.5l5 5 5-5" stroke="#667085" strokeWidth="1.67" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
    </div>
  );
}

function TextareaField({ label, placeholder, required = false, value, onChange }) {
  return (
    <div className="flex flex-col gap-1.5 w-full">
      <div className="flex gap-0.5 items-center">
        <label className="font-['Inter',sans-serif] font-medium text-[14px] leading-5 text-[#344054]">
          {label}
        </label>
        {required && (
          <span className="font-['Inter',sans-serif] font-medium text-[14px] leading-5 text-[#0086c9]">*</span>
        )}
      </div>
      <div className="relative bg-white border border-[#d0d5dd] rounded-lg shadow-[0px_1px_2px_0px_rgba(16,24,40,0.05)] flex items-start px-3.5 py-3 w-full min-h-[66px]">
        <textarea
          placeholder={placeholder}
          value={value}
          onChange={onChange}
          rows={2}
          className="flex-1 font-['Inter',sans-serif] font-normal text-[16px] leading-6 text-[#101828] placeholder-[#667085] bg-transparent outline-none resize-none w-full"
        />
        <svg
          className="absolute bottom-1.5 right-1.5 text-[#98a2b3]"
          width="12" height="12" viewBox="0 0 12 12" fill="none"
        >
          <path d="M11 1L1 11M11 6L6 11" stroke="#98a2b3" strokeWidth="1.5" strokeLinecap="round" />
        </svg>
      </div>
    </div>
  );
}

export default function LeadCaptureCompanyDetails({
  onBack,
  formData,
  onChange,
  onSaveAndContinue,
  onSaveAndClose,
  loading = false,
  error = null,
}) {
  const canContinue = formData.telephone.trim() !== '' && formData.company.trim() !== ''

  return (
    <div className="bg-white flex flex-col items-center overflow-clip rounded-[24px] w-full min-h-full">
      {/* iOS Status Bar */}
      <div className="flex items-center justify-between px-4 py-2 w-full shrink-0">
        <span className="font-['Inter',sans-serif] font-normal text-[15px] text-black tracking-[-0.3px]">
          9:41
        </span>
        <div className="flex items-center gap-1.5">
          <svg width="17" height="12" viewBox="0 0 17 12" fill="none">
            <rect x="0" y="6" width="3" height="6" rx="1" fill="black"/>
            <rect x="4.5" y="4" width="3" height="8" rx="1" fill="black"/>
            <rect x="9" y="2" width="3" height="10" rx="1" fill="black"/>
            <rect x="13.5" y="0" width="3" height="12" rx="1" fill="black"/>
          </svg>
          <svg width="16" height="12" viewBox="0 0 16 12" fill="none">
            <path d="M8 9.5a1.5 1.5 0 100 3 1.5 1.5 0 000-3z" fill="black"/>
            <path d="M8 6C6.1 6 4.4 6.8 3.2 8l1.4 1.4C5.5 8.5 6.7 8 8 8s2.5.5 3.4 1.4L12.8 8C11.6 6.8 9.9 6 8 6z" fill="black"/>
            <path d="M8 2.5C4.9 2.5 2.1 3.8.1 5.9L1.5 7.3C3.1 5.5 5.4 4.5 8 4.5s4.9 1 6.5 2.8l1.4-1.4C13.9 3.8 11.1 2.5 8 2.5z" fill="black"/>
          </svg>
          <svg width="25" height="12" viewBox="0 0 25 12" fill="none">
            <rect x="0.5" y="0.5" width="21" height="11" rx="3.5" stroke="black" strokeOpacity="0.35"/>
            <rect x="2" y="2" width="18" height="8" rx="2" fill="black"/>
            <path d="M23 4v4a2 2 0 000-4z" fill="black" fillOpacity="0.4"/>
          </svg>
        </div>
      </div>

      {/* Top App Bar */}
      <header className="bg-white flex gap-1 items-center px-1 py-2 w-full shrink-0 sticky top-0 z-10">
        <button
          onClick={onBack}
          className="flex items-center justify-center w-12 h-12 shrink-0"
        >
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z" fill="#1a1c18"/>
          </svg>
        </button>
        <h1 className="flex-1 font-['Inter',sans-serif] font-medium text-[20px] leading-[30px] text-[#1a1c18]">
          Capturing Lead
        </h1>
      </header>

      {/* Body */}
      <main className="flex flex-col flex-1 w-full overflow-y-auto">
        <div className="flex flex-col flex-1 w-full px-4">
          <div className="bg-white flex flex-col flex-1 gap-2.5 pb-4 pt-4 px-3 w-full">

            {/* Page Header */}
            <div className="flex flex-col gap-5 w-full shrink-0">
              <div className="flex flex-col gap-4 w-full">
                <div className="flex flex-col gap-1 w-full">
                  <h2 className="font-['Inter',sans-serif] font-semibold text-[18px] leading-7 text-[#101828] w-full">
                    Company Details
                  </h2>
                  <p className="font-['Inter',sans-serif] font-normal text-[14px] leading-5 text-[#475467] w-full">
                    Please fill in lead details.
                  </p>
                </div>
              </div>
              <hr className="border-0 border-t border-[#e4e7ec] w-full" />
            </div>

            {/* Progress Steps — step 1 current */}
            <div className="flex items-center justify-center w-full shrink-0 py-1">
              <ProgressSteps steps={["current", "incomplete", "incomplete"]} />
            </div>

            {/* Form Fields */}
            <div className="flex flex-col gap-4 w-full">
              <SelectField
                label="Customer"
                placeholder="Type in a customer"
                value={formData.customer}
                onChange={e => onChange('customer', e.target.value)}
              />
              <InputField
                label="Telephone"
                placeholder=""
                required
                type="tel"
                value={formData.telephone}
                onChange={e => onChange('telephone', e.target.value)}
              />
              <InputField
                label="Company"
                placeholder="Name of company"
                required
                value={formData.company}
                onChange={e => onChange('company', e.target.value)}
              />
              <InputField
                label="Email"
                placeholder="name@example.com"
                type="email"
                value={formData.email}
                onChange={e => onChange('email', e.target.value)}
              />

              {/* Physical Address + Postal Code */}
              <div className="flex gap-2.5 items-start w-full">
                <div className="flex-[3]">
                  <InputField
                    label="Physical Address"
                    placeholder=""
                    value={formData.physicalAddress}
                    onChange={e => onChange('physicalAddress', e.target.value)}
                  />
                </div>
                <div className="flex-1">
                  <InputField
                    label="Postal Code"
                    placeholder=""
                    value={formData.postalCode}
                    onChange={e => onChange('postalCode', e.target.value)}
                  />
                </div>
              </div>

              <InputField
                label="Website"
                placeholder="www.example.com"
                type="url"
                value={formData.website}
                onChange={e => onChange('website', e.target.value)}
              />
              <TextareaField
                label="Contact Notes"
                placeholder="Enter a description..."
                required
                value={formData.contactNotes}
                onChange={e => onChange('contactNotes', e.target.value)}
              />
            </div>

            {/* Error message */}
            {error && (
              <p className="font-['Inter',sans-serif] text-sm text-red-600 text-center px-2">
                {error}
              </p>
            )}

            {/* Action Buttons */}
            <div className="flex flex-col gap-2.5 w-full mt-1 pb-4">
              <button
                disabled={!canContinue || loading}
                onClick={onSaveAndContinue}
                className={`rounded-lg shadow-[0px_1px_2px_0px_rgba(16,24,40,0.05)] flex items-center justify-center gap-1.5 px-[18px] py-3 w-full transition-colors ${
                  canContinue && !loading
                    ? 'bg-[#0086c9] border border-[#0086c9] cursor-pointer'
                    : 'bg-[#f2f4f7] border border-[#e4e7ec] cursor-not-allowed'
                }`}
              >
                <span className={`font-['Inter',sans-serif] font-semibold text-[16px] leading-6 ${
                  canContinue && !loading ? 'text-white' : 'text-[#98a2b3]'
                }`}>
                  {loading ? 'Saving…' : 'Save & Continue'}
                </span>
              </button>

              <button
                disabled={loading}
                onClick={onSaveAndClose}
                className="relative bg-white border border-[#7cd4fd] rounded-lg shadow-[0px_1px_2px_0px_rgba(16,24,40,0.05),inset_0px_0px_0px_1px_rgba(16,24,40,0.18),inset_0px_-2px_0px_0px_rgba(16,24,40,0.05)] flex items-center justify-center gap-1.5 px-[18px] py-3 w-full disabled:opacity-60"
              >
                <span className="font-['Inter',sans-serif] font-semibold text-[16px] leading-6 text-[#026aa2]">
                  {loading ? 'Saving…' : 'Save & Close'}
                </span>
              </button>
            </div>

          </div>
        </div>
      </main>
    </div>
  );
}
