export default function LeadDetails() {
  return (
    <div className="bg-[#f5f5f5] flex flex-col items-center overflow-clip rounded-[24px] w-full min-h-full">
      {/* iOS Status Bar */}
      <div className="bg-white flex items-center justify-between px-4 py-2 w-full shrink-0">
        <span className="font-['Inter',sans-serif] font-normal text-[15px] text-black tracking-[-0.3px]">
          9:41
        </span>
        <div className="flex items-center gap-1.5">
          {/* Signal */}
          <svg width="17" height="12" viewBox="0 0 17 12" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect x="0" y="6" width="3" height="6" rx="1" fill="black"/>
            <rect x="4.5" y="4" width="3" height="8" rx="1" fill="black"/>
            <rect x="9" y="2" width="3" height="10" rx="1" fill="black"/>
            <rect x="13.5" y="0" width="3" height="12" rx="1" fill="black"/>
          </svg>
          {/* WiFi */}
          <svg width="16" height="12" viewBox="0 0 16 12" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M8 9.5a1.5 1.5 0 100 3 1.5 1.5 0 000-3z" fill="black"/>
            <path d="M8 6C6.1 6 4.4 6.8 3.2 8l1.4 1.4C5.5 8.5 6.7 8 8 8s2.5.5 3.4 1.4L12.8 8C11.6 6.8 9.9 6 8 6z" fill="black"/>
            <path d="M8 2.5C4.9 2.5 2.1 3.8.1 5.9L1.5 7.3C3.1 5.5 5.4 4.5 8 4.5s4.9 1 6.5 2.8l1.4-1.4C13.9 3.8 11.1 2.5 8 2.5z" fill="black"/>
          </svg>
          {/* Battery */}
          <svg width="25" height="12" viewBox="0 0 25 12" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect x="0.5" y="0.5" width="21" height="11" rx="3.5" stroke="black" strokeOpacity="0.35"/>
            <rect x="2" y="2" width="18" height="8" rx="2" fill="black"/>
            <path d="M23 4v4a2 2 0 000-4z" fill="black" fillOpacity="0.4"/>
          </svg>
        </div>
      </div>

      {/* Top App Bar */}
      <header className="bg-white flex gap-1 items-center px-1 py-2 w-full shrink-0 sticky top-0 z-10">
        <button className="flex items-center justify-center w-12 h-12 shrink-0">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z" fill="#1a1c18"/>
          </svg>
        </button>
        <h1 className="flex-1 font-['Inter',sans-serif] font-medium text-[20px] leading-[30px] text-[#1a1c18]">
          Lead Details
        </h1>
      </header>

      {/* Body */}
      <main className="flex flex-col gap-0 w-full flex-1 overflow-y-auto px-0 pt-6 pb-3">
        <div className="flex flex-col gap-2 items-start px-4 w-full">

          {/* Contact Card */}
          <div className="bg-[#f0f9ff] border border-[#0ba5ec] rounded-2xl flex flex-col gap-0 items-center p-5 w-full">
            <div className="flex flex-col gap-4 items-start w-full">
              <div className="flex flex-col gap-3 items-start w-full">
                <div className="flex flex-col gap-1.5 items-start w-full">
                  <p className="font-['Inter',sans-serif] font-semibold text-[18px] leading-[28px] text-[#101828] w-full">
                    Mobile App Development
                  </p>
                  <div className="flex flex-col gap-0 w-full">
                    {/* Row 1: email + phone */}
                    <div className="flex gap-2 items-center h-8 w-full">
                      <div className="flex flex-1 gap-2.5 items-center">
                        <svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M1.5 4.5A1.5 1.5 0 013 3h12a1.5 1.5 0 011.5 1.5v9A1.5 1.5 0 0115 15H3a1.5 1.5 0 01-1.5-1.5v-9zm1.5 0v.621l6 3.75 6-3.75V4.5H3zm12 2.379l-5.553 3.47a.75.75 0 01-.794 0L3 6.879V13.5h12V6.879z" fill="#475467"/>
                        </svg>
                        <span className="font-['Inter',sans-serif] font-normal text-[12px] leading-[18px] text-[#475467] whitespace-nowrap">
                          olivia@untitledui.com
                        </span>
                      </div>
                      <div className="flex flex-1 gap-2.5 items-center">
                        <svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M6.63 4.32C6.44 3.84 5.89 3 5.28 3 4.18 3 3 4.16 3 5.26c0 .7.3 1.39.73 2.1.65 1.06 1.66 2.16 2.78 3.14 1.12.98 2.4 1.85 3.54 2.38.77.36 1.55.62 2.2.62 1.1 0 2.26-1.18 2.26-2.28 0-.6-.82-1.14-1.32-1.35l-1.04-.47c-.5-.22-.97-.02-1.18.22l-.46.54c-.24.27-.63.27-.63.27s-1.75-.63-3.05-2.4c0 0-.13-.37.07-.65l.49-.61c.2-.27.35-.76.1-1.26l-.59-1.18z" fill="#475467"/>
                        </svg>
                        <span className="font-['Inter',sans-serif] font-normal text-[12px] leading-[18px] text-[#475467] whitespace-nowrap">
                          012-345-6789
                        </span>
                      </div>
                    </div>
                    {/* Row 2: company */}
                    <div className="flex gap-2 items-center h-8 w-full">
                      <div className="flex flex-1 gap-2.5 items-center">
                        <svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M3 15.75V3.75A.75.75 0 013.75 3h10.5a.75.75 0 01.75.75V15.75M3 15.75H1.5M3 15.75h3M16.5 15.75H15M16.5 15.75H15M6 15.75v-3.75h6v3.75M6 15.75h6M6.75 6H7.5M10.5 6h.75M6.75 9H7.5M10.5 9h.75" stroke="#475467" strokeWidth="1.125" strokeLinecap="round" strokeLinejoin="round"/>
                        </svg>
                        <span className="font-['Inter',sans-serif] font-normal text-[12px] leading-[18px] text-[#475467] whitespace-nowrap">
                          Xiquel Group
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Card with Tabs + Details */}
          <div className="flex flex-col w-full rounded-2xl overflow-hidden">
            {/* Tab Bar */}
            <div className="bg-white flex flex-col gap-0 items-center py-5 w-full">
              <div className="flex flex-col gap-4 items-center max-w-[1280px] px-5 w-full">
                <div className="flex flex-col gap-4 items-center max-w-[360px] w-full">
                  <div className="bg-[#f9fafb] border border-[#e4e7ec] rounded-lg flex gap-0.5 items-center w-full px-0.5 py-0.5">
                    <button className="flex flex-1 gap-2 h-9 items-center justify-center overflow-clip px-3 py-2 rounded-lg">
                      <span className="font-['Inter',sans-serif] font-semibold text-[14px] leading-[20px] text-[#667085] whitespace-nowrap">
                        Company Details
                      </span>
                    </button>
                    <div className="bg-white border border-[#d0d5dd] shadow-[0px_1px_2px_0px_rgba(16,24,40,0.05)] flex flex-1 gap-2 h-9 items-center justify-center overflow-clip px-3 py-2 rounded-lg">
                      <span className="font-['Inter',sans-serif] font-semibold text-[14px] leading-[20px] text-[#344054] whitespace-nowrap">
                        Lead Details
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Details Section */}
            <div className="bg-white flex flex-col gap-4 pb-8 pt-4 px-1 rounded-b-2xl w-full">
              {/* Owner ID */}
              <div className="px-4">
                <p className="font-['Inter',sans-serif] text-[#101828]">
                  <span className="font-semibold text-[16px] leading-[24px]">Owner ID:</span>
                  <span className="font-normal text-[14px] leading-[20px] text-[#475467]">{" "}2349</span>
                </p>
              </div>

              {/* Detail fields */}
              <div className="flex flex-col gap-5 px-4 w-full">
                {[
                  { label: "First Name", value: "John" },
                  { label: "Last Name", value: "Doe" },
                  { label: "Mobile", value: "+27 62 008 8239" },
                  { label: "Prospect Level", value: "1-Prospect-50%" },
                  { label: "Lead Source", value: "Event" },
                  { label: "Campaign", value: "EzraME" },
                ].map(({ label, value }) => (
                  <div key={label} className="flex flex-col gap-1 w-full">
                    <p className="font-['Inter',sans-serif] font-semibold text-[16px] leading-[24px] text-[#101828] w-full">
                      {label}
                    </p>
                    <p className="font-['Inter',sans-serif] font-normal text-[14px] leading-[20px] text-[#475467] w-full">
                      {value}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          </div>

        </div>
      </main>
    </div>
  );
}
