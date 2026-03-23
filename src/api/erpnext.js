const API_KEY    = import.meta.env.VITE_ERPNEXT_API_KEY;
const API_SECRET = import.meta.env.VITE_ERPNEXT_API_SECRET;

const headers = {
  'Content-Type': 'application/json',
  'Authorization': `token ${API_KEY}:${API_SECRET}`,
};

/**
 * Create a Lead in ERPNext combining data from both capture steps.
 * Custom fields (custom_*) must be added to the Lead DocType in ERPNext
 * via Customize Form before they will be accepted.
 *
 * @returns {{ success: boolean, data: object|null, error: string|null }}
 */
export async function createLead(companyData, productData = {}) {
  const body = {
    lead_name:               companyData.customer        || companyData.company || 'New Lead',
    company_name:            companyData.company         || '',
    email_id:                companyData.email           || '',
    phone:                   companyData.telephone       || '',
    website:                 companyData.website         || '',
    custom_physical_address: companyData.physicalAddress || '',
    custom_postal_code:      companyData.postalCode      || '',
    custom_contact_notes:    companyData.contactNotes    || '',
    custom_start_trail:      productData.startTrail      || '',
    custom_prospect_value:   productData.prospectValue   || '',
    custom_business_unit:    productData.businessUnit    || '',
  };

  try {
    const res = await fetch('/api/resource/Lead', {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
    });
    const json = await res.json();
    if (!res.ok) {
      const msg = json.exception ?? json._server_messages ?? json.message ?? 'Unknown error';
      return { success: false, data: null, error: String(msg) };
    }
    return { success: true, data: json.data, error: null };
  } catch (err) {
    return { success: false, data: null, error: err.message };
  }
}

/**
 * Fetch a single Lead by its ERPNext document name (e.g. "CRM-LEAD-2025-00001").
 *
 * @returns {{ success: boolean, data: object|null, error: string|null }}
 */
export async function getLead(name) {
  try {
    const res = await fetch(
      `/api/resource/Lead/${encodeURIComponent(name)}`,
      { headers }
    );
    const json = await res.json();
    if (!res.ok) {
      const msg = json.exception ?? json.message ?? 'Unknown error';
      return { success: false, data: null, error: String(msg) };
    }
    return { success: true, data: json.data, error: null };
  } catch (err) {
    return { success: false, data: null, error: err.message };
  }
}
