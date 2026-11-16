# GraBiTT - Location-Based Store Feed API Specification (v2.0 - Updated)
**Target Endpoint:** `/webservice.asmx/GetStoreFeedByLocation`  
**Purpose:** Multi-city & Location-aware dynamic feed for Home / Store Page (Categories, Vendors, Banners, Serviceability, Pagination).

---

## 1. Request Details

* **Method:** `GET` or `POST`
* **URL:** `https://grabitt.in/webservice.asmx/GetStoreFeedByLocation`
* **Parameters:**

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `pincode` | `string` | **Yes** (if lat/lon not provided) | `""` | 6-digit delivery pincode (e.g. `400001`, `411001`, `586101`) |
| `lat` | `string` / `double` | Optional | `""` | User delivery latitude (e.g. `18.9220`) |
| `lon` | `string` / `double` | Optional | `""` | User delivery longitude (e.g. `72.8347`) |
| `lang` | `string` | No | `en` | Language code: `en` (English) or `kn` (Kannada) |
| `category_id` | `string` | No | `""` | Filter vendors by category ID (leave empty/null for all) |
| `page` | `int` | No | `1` | Page number for vendor pagination |
| `pageSize` | `int` | No | `10` | Number of vendors per page |

---

## 2. Location Priority Rule (Pincode vs Lat/Lon)

Senior requirement ke according delivery location priority is tarah handle hogi:

1. **Priority 1 (GPS Coordinates - `lat` & `lon`):**
   * Agar request mein valid `lat` aur `lon` aate hain, toh backend vendor ki delivery radius (e.g. 5-7 km radius) se serviceability aur vendor list calculate karega (High precision).
2. **Priority 2 (Pincode - Fallback):**
   * Agar `lat` aur `lon` empty ya `0` hain, toh backend `pincode` ko fallback manega aur `Vendor_Serviceable_Pincodes` (delivery coverage mapping) se serviceability check karega.
   * **Note:** Serviceability vendor ke dukan ke pincode se check **nahi** hogi, balki vendor ke **Delivery Coverage Pincodes** se check hogi.

---

## 3. Shop Status vs Serviceability Rule

* **`is_serviceable` (Area Coverage):**
  * `true` -> GraBiTT is area / pincode me delivery deliver karta hai (restaurants exist for this area).
  * `false` -> GraBiTT is area me bilkul deliver nahi karta (Coming soon).
* **`ShopStatus` (Vendor Open/Closed):**
  * `true` -> Dukan abhi open hai aur orders le rahi hai.
  * `false` -> Dukan abhi temporarily closed hai (e.g., raat ka samay ya off-day).
  * ⚠️ **Important:** Agar area ke saare vendors raat ko closed (`ShopStatus: false`) hain, tab bhi `is_serviceable: true` hi rahega, area unserviceable nahi kehlayega.

---

## 4. Response Formats (JSON) - Consistent Schema

*Har response (Success, Unserviceable, Error) ka schema strictly **same** rahega taaki mobile app me parsing crash na ho.*

### Case A: Serviceable Area (Vendors & Categories Found)
```json
{
  "status": "Success",
  "is_serviceable": true,
  "city": "Mumbai",
  "pincode": "400001",
  "message": "Store feed loaded successfully",
  "categories": [
    {
      "id": "1",
      "CategoryName": "Restaurants",
      "CategoryImage": "https://grabitt.in/uploads/categories/food.png"
    },
    {
      "id": "2",
      "CategoryName": "Grocery",
      "CategoryImage": "https://grabitt.in/uploads/categories/grocery.png"
    }
  ],
  "vendors": [
    {
      "VendorID": "101",
      "VendorName": "Mumbai Darbar",
      "CategoryID": "1",
      "CategoryName": "Restaurants",
      "City": "Mumbai",
      "MobileNo": "9876543210",
      "OpeningTime": "09:00 AM",
      "ClosingTime": "11:00 PM",
      "ShopStatus": true,
      "Distance": "2.4 km",
      "Image1": "https://grabitt.in/uploads/vendors/vd1_1.jpg",
      "Image2": "https://grabitt.in/uploads/vendors/vd1_2.jpg",
      "Image3": null,
      "Image4": null,
      "Image5": null
    }
  ],
  "banners": [
    {
      "BannerID": "1",
      "Image": "https://grabitt.in/uploads/banners/mumbai_welcome.jpg",
      "ImageTitle": "Welcome to Mumbai",
      "ImageDescription": "Flat 50% off on your first order",
      "IsActive": true
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 10,
    "totalCount": 24,
    "hasMore": true
  }
}
```

---

### Case B: Unserviceable Area (Coming Soon / No Delivery Coverage)
```json
{
  "status": "Success",
  "is_serviceable": false,
  "city": "Pune",
  "pincode": "411001",
  "message": "Sorry, we are not delivering in this area yet! We are coming soon to your area.",
  "categories": [],
  "vendors": [],
  "banners": [],
  "pagination": {
    "page": 1,
    "pageSize": 10,
    "totalCount": 0,
    "hasMore": false
  }
}
```

---

### Case C: Error / Invalid Parameters (Consistent Schema)
```json
{
  "status": "Fail",
  "is_serviceable": false,
  "city": "",
  "pincode": "",
  "message": "Invalid pincode or coordinates provided",
  "categories": [],
  "vendors": [],
  "banners": [],
  "pagination": {
    "page": 1,
    "pageSize": 10,
    "totalCount": 0,
    "hasMore": false
  }
}
```

---

## 5. Important Field Requirements Summary

1. **`CategoryID` inside Vendors:** Har vendor object me `CategoryID` hona lazmi hai taaki app category tabs switch karte waqt client-side ya instant filter kar sake.
2. **Localization (`lang`):** 
   * Agar `lang=kn` pass ho, toh `CategoryName` aur `VendorName` Kannada columns se aayein (e.g. `CategoryName_KN`, `VendorName_KN`). Default `en` rahega.
3. **Full Image URLs:** Backend full absolute URLs return karega (`https://grabitt.in/uploads/...`), relative paths (`images/...`) nahi.
4. **Pagination:** `page` aur `pageSize` ke according vendors slice hoke aayenge, aur response ke `pagination` object me `hasMore: true/false` aayega.

---

## 6. Backend Database Structure & Queries

### Step 1: Delivery Coverage Table
Vendor ka apna address alag hota hai aur uska delivery area alag. Isliye delivery coverage table use hogi:

```sql
CREATE TABLE Vendor_Serviceable_Pincodes (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    VendorID INT NOT NULL,
    Pincode VARCHAR(10) NOT NULL,
    City VARCHAR(50) NULL,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Vendor FOREIGN KEY (VendorID) REFERENCES Vendors(VendorID)
);

CREATE INDEX IX_Vendor_Pincode ON Vendor_Serviceable_Pincodes (Pincode, IsActive);
```

### Step 2: Vendor Query with Pagination & Localization

```sql
-- Parameters: @pincode, @lang, @category_id, @page, @pageSize
DECLARE @offset INT = (@page - 1) * @pageSize;

-- Total Vendors Count
SELECT COUNT(DISTINCT v.VendorID)
FROM Vendors v
INNER JOIN Vendor_Serviceable_Pincodes vp ON v.VendorID = vp.VendorID
WHERE vp.Pincode = @pincode 
  AND vp.IsActive = 1 
  AND v.IsActive = 1
  AND (@category_id IS NULL OR @category_id = '' OR v.CategoryID = @category_id);

-- Paged Vendor List
SELECT 
    v.VendorID,
    CASE WHEN @lang = 'kn' AND ISNULL(v.VendorName_KN, '') <> '' THEN v.VendorName_KN ELSE v.VendorName END AS VendorName,
    v.CategoryID,
    CASE WHEN @lang = 'kn' AND ISNULL(c.CategoryName_KN, '') <> '' THEN c.CategoryName_KN ELSE c.CategoryName END AS CategoryName,
    v.City,
    v.MobileNo,
    v.OpeningTime,
    v.ClosingTime,
    v.ShopStatus,
    -- Full Image URLs
    CASE WHEN v.Image1 IS NOT NULL AND v.Image1 <> '' THEN 'https://grabitt.in/' + v.Image1 ELSE NULL END AS Image1,
    CASE WHEN v.Image2 IS NOT NULL AND v.Image2 <> '' THEN 'https://grabitt.in/' + v.Image2 ELSE NULL END AS Image2,
    CASE WHEN v.Image3 IS NOT NULL AND v.Image3 <> '' THEN 'https://grabitt.in/' + v.Image3 ELSE NULL END AS Image3,
    CASE WHEN v.Image4 IS NOT NULL AND v.Image4 <> '' THEN 'https://grabitt.in/' + v.Image4 ELSE NULL END AS Image4,
    CASE WHEN v.Image5 IS NOT NULL AND v.Image5 <> '' THEN 'https://grabitt.in/' + v.Image5 ELSE NULL END AS Image5
FROM Vendors v
INNER JOIN Categories c ON v.CategoryID = c.id
INNER JOIN Vendor_Serviceable_Pincodes vp ON v.VendorID = vp.VendorID
WHERE vp.Pincode = @pincode 
  AND vp.IsActive = 1 
  AND v.IsActive = 1
  AND (@category_id IS NULL OR @category_id = '' OR v.CategoryID = @category_id)
ORDER BY v.ShopStatus DESC, v.VendorID ASC
OFFSET @offset ROWS FETCH NEXT @pageSize ROWS ONLY;
```

### Step 3: Categories Query for that Pincode
```sql
SELECT DISTINCT 
    c.id,
    CASE WHEN @lang = 'kn' AND ISNULL(c.CategoryName_KN, '') <> '' THEN c.CategoryName_KN ELSE c.CategoryName END AS CategoryName,
    CASE WHEN c.CategoryImage IS NOT NULL AND c.CategoryImage <> '' THEN 'https://grabitt.in/' + c.CategoryImage ELSE NULL END AS CategoryImage
FROM Categories c
INNER JOIN Vendors v ON c.id = v.CategoryID
INNER JOIN Vendor_Serviceable_Pincodes vp ON v.VendorID = vp.VendorID
WHERE vp.Pincode = @pincode AND vp.IsActive = 1 AND v.IsActive = 1;
```

---

## 7. Sample ASP.NET C# (`.asmx`) Controller Implementation

```csharp
[WebMethod]
[ScriptMethod(ResponseFormat = ResponseFormat.Json)]
public void GetStoreFeedByLocation(
    string pincode, 
    string lat = "", 
    string lon = "", 
    string lang = "en", 
    string category_id = "", 
    int page = 1, 
    int pageSize = 10)
{
    Context.Response.Clear();
    Context.Response.ContentType = "application/json";

    if (page < 1) page = 1;
    if (pageSize < 1) pageSize = 10;

    // Helper method to return consistent schema on failure
    void ReturnFail(string msg)
    {
        var failObj = new
        {
            status = "Fail",
            is_serviceable = false,
            city = "",
            pincode = pincode ?? "",
            message = msg,
            categories = new object[] { },
            vendors = new object[] { },
            banners = new object[] { },
            pagination = new { page = page, pageSize = pageSize, totalCount = 0, hasMore = false }
        };
        Context.Response.Write(JsonConvert.SerializeObject(failObj));
    }

    if (string.IsNullOrWhiteSpace(pincode) && (string.IsNullOrWhiteSpace(lat) || string.IsNullOrWhiteSpace(lon)))
    {
        ReturnFail("Either pincode or valid coordinates (lat/lon) are required");
        return;
    }

    try
    {
        // 1. Resolve delivery location (Lat/Lon priority over Pincode)
        string effectivePincode = pincode;
        if (!string.IsNullOrWhiteSpace(lat) && !string.IsNullOrWhiteSpace(lon))
        {
            // If GPS coordinates provided, resolve or verify coverage via geo-lookup
            // effectivePincode = GetPincodeFromLatLon(lat, lon);
        }

        // 2. Fetch total count & paged vendors for this coverage
        int totalVendors = GetTotalVendorsCount(effectivePincode, category_id);
        
        if (totalVendors == 0)
        {
            // Area is not serviceable
            var emptyObj = new
            {
                status = "Success",
                is_serviceable = false,
                city = GetCityByPincode(effectivePincode) ?? "",
                pincode = effectivePincode,
                message = "Sorry, we are not delivering in this area yet! We are coming soon to your area.",
                categories = new object[] { },
                vendors = new object[] { },
                banners = new object[] { },
                pagination = new { page = page, pageSize = pageSize, totalCount = 0, hasMore = false }
            };
            Context.Response.Write(JsonConvert.SerializeObject(emptyObj));
            return;
        }

        DataTable dtVendors = GetPagedVendorsFromDB(effectivePincode, category_id, lang, page, pageSize);
        DataTable dtCategories = GetCategoriesForLocationFromDB(effectivePincode, lang);
        DataTable dtBanners = GetBannersForLocationFromDB(effectivePincode);

        bool hasMore = (page * pageSize) < totalVendors;

        var feedObj = new
        {
            status = "Success",
            is_serviceable = true,
            city = dtVendors.Rows.Count > 0 ? dtVendors.Rows[0]["City"].ToString() : "",
            pincode = effectivePincode,
            message = "Store feed loaded successfully",
            categories = dtCategories,
            vendors = dtVendors,
            banners = dtBanners,
            pagination = new
            {
                page = page,
                pageSize = pageSize,
                totalCount = totalVendors,
                hasMore = hasMore
            }
        };

        Context.Response.Write(JsonConvert.SerializeObject(feedObj));
    }
    catch (Exception ex)
    {
        ReturnFail("Server error: " + ex.Message);
    }
}
```
