function CloudIllustration() {
  return (
    <div className="relative w-[220px] h-[160px] shrink-0">
      {/* Large background circle */}
      <svg className="absolute left-[30px] top-0 w-[160px] h-[160px]" viewBox="0 0 160 160" fill="none">
        <circle cx="80" cy="80" r="80" fill="#f2f4f7" />
      </svg>

      {/* Decorative small circles */}
      <svg className="absolute left-[18px] top-[12px] w-4 h-4" viewBox="0 0 16 16" fill="none">
        <circle cx="8" cy="8" r="8" fill="#e4e7ec" />
      </svg>
      <svg className="absolute left-[192px] top-[120px] w-3 h-3" viewBox="0 0 12 12" fill="none">
        <circle cx="6" cy="6" r="6" fill="#e4e7ec" />
      </svg>
      <svg className="absolute left-[15px] top-[128px] w-5 h-5" viewBox="0 0 20 20" fill="none">
        <circle cx="10" cy="10" r="10" fill="#d0d5dd" />
      </svg>
      <svg className="absolute left-[200px] top-[36px] w-5 h-5" viewBox="0 0 20 20" fill="none">
        <circle cx="10" cy="10" r="10" fill="#d0d5dd" />
      </svg>
      <svg className="absolute left-[184px] top-[4px] w-3.5 h-3.5" viewBox="0 0 14 14" fill="none">
        <circle cx="7" cy="7" r="7" fill="#e4e7ec" />
      </svg>

      {/* Cloud shape */}
      <svg
        className="absolute left-[24px] top-[16px] w-[174px] h-[100px]"
        viewBox="0 0 174 100"
        fill="none"
      >
        {/* Main cloud body */}
        <path
          d="M138 70H44C31.3 70 21 59.7 21 47s10.3-23 23-23c.9 0 1.8.1 2.7.2C50.4 13.4 62 5 75.5 5c16.8 0 30.5 13.2 31 30 .8-.1 1.7-.1 2.5-.1 14.4 0 26 11.6 26 26 0 5-.7 9-2 9z"
          fill="white"
          opacity="0.9"
          style={{ filter: "drop-shadow(0px 4px 16px rgba(0,0,0,0.08))" }}
        />
        {/* Second cloud layer for depth */}
        <path
          d="M155 85H55C40.1 85 28 72.9 28 58c0-12.1 8.1-22.3 19.2-25.5C51.9 22.2 63.6 14 77 14c14.5 0 26.8 9.5 30.8 22.7 1.4-.3 2.8-.4 4.2-.4 13.8 0 25 11.2 25 25 0 1.4-.1 2.7-.3 4 9.3 2.2 16.3 10.5 16.3 20.4V86c-1.2-.7-2.5-1-4-1z"
          fill="white"
          opacity="0.5"
          style={{ filter: "drop-shadow(0px 2px 8px rgba(0,0,0,0.05))" }}
        />
      </svg>

      {/* Search badge — dark blurred circle with magnify icon */}
      <div
        className="absolute left-[82px] top-[84px] w-14 h-14 rounded-full flex items-center justify-center overflow-clip"
        style={{ background: "rgba(52,64,84,0.4)", backdropFilter: "blur(4px)" }}
      >
        <svg width="28" height="28" viewBox="0 0 28 28" fill="none">
          <circle cx="13" cy="13" r="8" stroke="white" strokeWidth="2.5" />
          <path d="M19 19l4 4" stroke="white" strokeWidth="2.5" strokeLinecap="round" />
        </svg>
      </div>
    </div>
  );
}

export default function EmptyLeadsList({ onNewLead }) {
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
        <button className="flex items-center justify-center w-12 h-12 shrink-0">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z" fill="#1a1c18" />
          </svg>
        </button>
        <h1 className="flex-1 font-['Inter',sans-serif] font-medium text-[20px] leading-[30px] text-[#1a1c18]">
          Sales
        </h1>
      </header>

      {/* Body — full-height gray bg, centred empty state */}
      <main className="flex flex-col flex-1 w-full bg-[#f5f5f5] overflow-y-auto">
        <div className="flex flex-col flex-1 items-start justify-center px-4 pt-6">
          <div className="flex flex-1 items-center justify-center w-full">
            <div className="flex flex-col items-center gap-16 w-full">
              {/* Content: illustration + text */}
              <div className="flex flex-col items-center gap-6 w-full">
                <CloudIllustration />

                <div className="flex flex-col items-center gap-2 max-w-[352px] text-center w-full">
                  <p className="font-['Inter',sans-serif] font-semibold text-[20px] leading-[30px] text-[#101828] w-full">
                    No Leads Available
                  </p>
                  <p className="font-['Inter',sans-serif] font-normal text-[16px] leading-6 text-[#475467] w-full">
                    You do not have any leads created, click New Lead to create your first lead.
                  </p>
                </div>
              </div>

              {/* CTA button */}
              <button
                onClick={onNewLead}
                className="relative bg-[#0086c9] border-2 border-white/[0.12] rounded-lg flex items-center gap-1.5 justify-center px-4 py-2.5 shadow-[0px_1px_2px_0px_rgba(16,24,40,0.05),inset_0px_0px_0px_1px_rgba(16,24,40,0.18),inset_0px_-2px_0px_0px_rgba(16,24,40,0.05)]"
              >
                <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
                  <path d="M10 4v12M4 10h12" stroke="white" strokeWidth="1.67" strokeLinecap="round" />
                </svg>
                <span className="font-['Inter',sans-serif] font-semibold text-[16px] leading-6 text-white">
                  New Lead
                </span>
              </button>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
