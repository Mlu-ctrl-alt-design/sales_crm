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
        <div className="absolute inset-0 rounded-full bg-[#f9fafb] border-[1.5px] border-[#e4e7ec] flex items-center justify-center">
          <div className="size-2 rounded-full bg-[#d0d5dd]" />
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

function ProgressSteps({ steps }) {
  return (
    <div className="flex items-center justify-center w-full">
      {steps.map((status, i) => (
        <div key={i} className="flex items-center">
          <StepIcon status={status} />
          {i < steps.length - 1 && <div className="h-0.5 w-12 bg-[#d9d9d9]" />}
        </div>
      ))}
    </div>
  );
}

function SelectField({ label, placeholder }) {
  return (
    <div className="flex flex-col gap-1.5 w-full">
      <label className="font-['Inter',sans-serif] font-medium text-[14px] leading-5 text-[#344054]">
        {label}
      </label>
      <div className="bg-white border border-[#d0d5dd] rounded-lg shadow-[0px_1px_2px_0px_rgba(16,24,40,0.05)] flex items-center justify-between gap-2 px-3.5 py-2.5 w-full cursor-pointer">
        <span className="flex-1 font-['Inter',sans-serif] font-normal text-[16px] leading-6 text-[#667085] truncate">
          {placeholder}
        </span>
        <svg width="20" height="20" viewBox="0 0 20 20" fill="none" className="shrink-0">
          <path d="M5 7.5l5 5 5-5" stroke="#667085" strokeWidth="1.67" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
    </div>
  );
}

function InputField({ label, placeholder }) {
  return (
    <div className="flex flex-col gap-1.5 w-full">
      <label className="font-['Inter',sans-serif] font-medium text-[14px] leading-5 text-[#344054]">
        {label}
      </label>
      <div className="bg-white border border-[#d0d5dd] rounded-lg shadow-[0px_1px_2px_0px_rgba(16,24,40,0.05)] flex items-center gap-2 px-3.5 py-2.5 w-full">
        <input
          type="text"
          placeholder={placeholder}
          className="flex-1 font-['Inter',sans-serif] font-normal text-[16px] leading-6 text-[#667085] placeholder-[#667085] bg-transparent outline-none"
        />
      </div>
    </div>
  );
}

export default function LeadCaptureProductOfInterest({ onBack }) {
  return (
    <div className="bg-white flex flex-col items-center overflow-clip rounded-[24px] w-full min-h-full">
      {/* iOS Status Bar */}
      <div className="flex items-center justify-between px-4 py-2 w-full shrink-0">
        <span className="font-['Inter',sans-serif] font-normal text-[15px] text-black tracking-[-0.3px]">
          9:41
        </span>
        <div className="flex items-center gap-1.5">
          <svg width="17" height="12" viewBox="0 0 17 12" fill="none">
            <rect x="0" y="6" width="3" height="6" rx="1" fill="black" />
            <rect x="4.5" y="4" width="3" height="8" rx="1" fill="black" />
            <rect x="9" y="2" width="3" height="10" rx="1" fill="black" />
            <rect x="13.5" y="0" width="3" height="12" rx="1" fill="black" />
          </svg>
          <svg width="16" height="12" viewBox="0 0 16 12" fill="none">
            <path d="M8 9.5a1.5 1.5 0 100 3 1.5 1.5 0 000-3z" fill="black" />
            <path d="M8 6C6.1 6 4.4 6.8 3.2 8l1.4 1.4C5.5 8.5 6.7 8 8 8s2.5.5 3.4 1.4L12.8 8C11.6 6.8 9.9 6 8 6z" fill="black" />
            <path d="M8 2.5C4.9 2.5 2.1 3.8.1 5.9L1.5 7.3C3.1 5.5 5.4 4.5 8 4.5s4.9 1 6.5 2.8l1.4-1.4C13.9 3.8 11.1 2.5 8 2.5z" fill="black" />
          </svg>
          <svg width="25" height="12" viewBox="0 0 25 12" fill="none">
            <rect x="0.5" y="0.5" width="21" height="11" rx="3.5" stroke="black" strokeOpacity="0.35" />
            <rect x="2" y="2" width="18" height="8" rx="2" fill="black" />
            <path d="M23 4v4a2 2 0 000-4z" fill="black" fillOpacity="0.4" />
          </svg>
        </div>
      </div>

      {/* Top App Bar */}
      <header className="bg-white flex gap-1 items-center px-1 py-2 w-full shrink-0 sticky top-0 z-10">
        <button onClick={onBack} className="flex items-center justify-center w-12 h-12 shrink-0">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z" fill="#1a1c18" />
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
              <div className="flex flex-col gap-1 w-full">
                <h2 className="font-['Inter',sans-serif] font-semibold text-[18px] leading-7 text-[#101828] w-full">
                  Product of Interest
                </h2>
                <p className="font-['Inter',sans-serif] font-normal text-[14px] leading-5 text-[#475467] w-full">
                  Please fill in lead details.
                </p>
              </div>
              <hr className="border-0 border-t border-[#e4e7ec] w-full" />
            </div>

            {/* Progress Steps — complete, complete, current */}
            <div className="flex items-center justify-center w-full shrink-0 py-1">
              <ProgressSteps steps={["complete", "complete", "current"]} />
            </div>

            {/* Form Fields */}
            <div className="flex flex-col gap-4 w-full">
              <SelectField label="Start Trail" placeholder="Choose an option" />
              <InputField label="Prospect Value" placeholder="R0.00" />
              <InputField label="Business Unit" placeholder="Business Unit" />
            </div>

            {/* Spacer to push buttons toward bottom */}
            <div className="flex-1" />

            {/* Action Buttons */}
            <div className="flex flex-col gap-2.5 w-full pb-4">
              <button
                disabled
                className="bg-[#f2f4f7] border border-[#e4e7ec] rounded-lg shadow-[0px_1px_2px_0px_rgba(16,24,40,0.05)] flex items-center justify-center gap-1.5 px-[18px] py-3 w-full cursor-not-allowed"
              >
                <span className="font-['Inter',sans-serif] font-semibold text-[16px] leading-6 text-[#98a2b3]">
                  Save &amp; Continue
                </span>
              </button>
              <button className="relative bg-white border border-[#7cd4fd] rounded-lg shadow-[0px_1px_2px_0px_rgba(16,24,40,0.05),inset_0px_0px_0px_1px_rgba(16,24,40,0.18),inset_0px_-2px_0px_0px_rgba(16,24,40,0.05)] flex items-center justify-center gap-1.5 px-[18px] py-3 w-full">
                <span className="font-['Inter',sans-serif] font-semibold text-[16px] leading-6 text-[#026aa2]">
                  Save &amp; Close
                </span>
              </button>
            </div>

          </div>
        </div>
      </main>
    </div>
  );
}
