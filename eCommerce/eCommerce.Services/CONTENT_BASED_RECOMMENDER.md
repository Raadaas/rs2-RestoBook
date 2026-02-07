# Content-Based Recommender System (ML.NET, cross-platform)

## 1. Arhitektura sustava

Sustav preporuke restorana temelji se isključivo na **sadržaju (content-based)** korisnika i restorana: ne koristi ponašanje drugih korisnika (nema collaborative filtering) niti Microsoft.ML.Recommender / matrix factorization. Svi koraci rade u **čistom ML.NET-u** (transformacije teksta i kategorija, normalizacija) i u **C#** (kosinusna sličnost, rangiranje), što osigurava **rad na macOS-u i svim platformama** bez nativnih biblioteka.

### Komponente

1. **Feature vektori restorana**  
   Za svaki restoran iz baze formira se vektor značajki:
   - **Tekst:** naziv + opis → featurizacija teksta (bag-of-words / TF-IDF stil) u ML.NET-u.
   - **Kategorije:** `CuisineTypeId`, `CityId` → one-hot encoding.
   - **Numeričke/binarne:** `HasParking`, `HasTerrace`, `IsKidFriendly` (0/1), `AverageRating` (float).

2. **Korisnički profil**  
   “Voljeni” restorani = restorani u kojima je korisnik imao **završenu rezervaciju (Completed)** ili je dao **recenziju s ocjenom ≥ 4**. Profil korisnika = **prosjek vektora** tih restorana, zatim **L2 normalizacija** (da kosinusna sličnost postane skalarni umnožak).

3. **Preporuka**  
   Kandidati = aktivni restorani koje korisnik još nije “volio”. Za svakog kandidata računa se **kosinusna sličnost** između korisničkog profila i vektora restorana. Vraća se **Top-N** prema toj sličnosti.

4. **Pokretanje**  
   Pri startu API-ja učitavaju se svi aktivni restorani, pipeline se **fitira** na njima, vektori se izvlače i drže u memoriji (rječnik po `RestaurantId`). Zahtjevi za preporuku samo čitaju te vektore i računaju sličnost.

---

## 2. ML.NET pipeline

Pipeline se gradi u `ContentBasedRestaurantRecommender.BuildFromRestaurants`:

```
Ulaz (RestaurantFeatureInput):
  RestaurantId, Name, Description, CuisineTypeId, CityId,
  HasParking, HasTerrace, IsKidFriendly, AverageRating
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│ 1. FeaturizeText("NameFeatures", "Name")                │  ← tekst → vektor (bag-of-words / TF-IDF stil)
│ 2. FeaturizeText("DescFeatures", "Description")         │
│ 3. OneHotEncoding("CuisineOneHot", "CuisineTypeId")     │  ← one-hot za kategorije
│ 4. OneHotEncoding("CityOneHot", "CityId")               │
│ 5. Concatenate("Features", NameFeatures, DescFeatures,  │  ← jedan dugi vektor
│                CuisineOneHot, CityOneHot,                │
│                HasParking, HasTerrace, IsKidFriendly,    │
│                AverageRating)                           │
│ 6. NormalizeLpNorm("Features", "Features", L2)         │  ← L2 norma = 1 → cosine = dot product
└─────────────────────────────────────────────────────────┘
        │
        ▼
Izlaz: RestaurantId + Features (float[]) za svaki red
      → spremljeno u rječnik _restaurantVectors
```

- **FeaturizeText** u ML.NET 1.5 daje vektor brojeva iz teksta (riječi, n-grami, težine u stilu bag-of-words / TF-IDF).
- **OneHotEncoding** pretvara kategorijski ID u binarni vektor (jedna dimenzija po kategoriji).
- **Concatenate** spaja sve u jedan vektor; **NormalizeLpNorm** L2 ga normalizira tako da za kosinusnu sličnost dovoljno je **dot product** između dva takva vektora.

---

## 3. C# primjer: model, transformacije, sličnost

### Model ulaza (pipeline)

```csharp
public class RestaurantFeatureInput
{
    public int RestaurantId { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    public int CuisineTypeId { get; set; }
    public int CityId { get; set; }
    public float HasParking { get; set; }
    public float HasTerrace { get; set; }
    public float IsKidFriendly { get; set; }
    public float AverageRating { get; set; }
}
```

### Građenje pipelinea (estimators + fit)

```csharp
var nameFeatures = _mlContext.Transforms.Text.FeaturizeText("NameFeatures", "Name");
var descFeatures = _mlContext.Transforms.Text.FeaturizeText("DescFeatures", "Description");
var cuisineOneHot = _mlContext.Transforms.Categorical.OneHotEncoding(...);
var cityOneHot = _mlContext.Transforms.Categorical.OneHotEncoding(...);
var concat = _mlContext.Transforms.Concatenate("Features", ...);
var normalize = _mlContext.Transforms.NormalizeLpNorm("Features", "Features", norm: NormFunction.L2);

_transformer = nameFeatures.Append(descFeatures).Append(...).Append(normalize).Fit(dataView);
```

### Kosinusna sličnost (L2-normalizirani vektori)

Za vektore s L2 normom 1 vrijedi: **cosine_similarity(a, b) = a · b**. U kodu:

```csharp
public static float CosineSimilarity(ReadOnlySpan<float> a, ReadOnlySpan<float> b)
{
    float dot = 0f;
    for (int i = 0; i < a.Length; i++) dot += a[i] * b[i];
    return dot;
}
```

### Korisnički profil i Top-N

- Profil = prosjek vektora “voljenih” restorana, zatim L2 normalizacija.
- Top-N = kandidati (aktivni restorani koje korisnik nije volio) sortirani po `CosineSimilarity(userProfile, restaurantVector)` silazno, uzmi prvih N.

Implementacija je u datoteci **`ContentBasedRestaurantRecommender.cs`** (BuildFromRestaurants, GetUserProfileVector, GetTopN, CosineSimilarity).

---

## 4. Zašto je content-based recommender dobar izbor

- **Jasna teorija:** Feature vektori (tekst + kategorije + numeričke značajke), profil korisnika kao prosjek vektora, kosinusna sličnost – sve je lako objasniti i nacrtati (shema pipelinea, formula sličnosti).
- **Bez collaborative filteringa:** Ne trebaju “slični korisnici” niti matrica user–item; fokus je na **sadržaju** restorana i na **profilu** jednog korisnika. To smanjuje složenost i olakšava evaluaciju (npr. precision/recall na “voljenim” restoranima).
- **ML.NET bez nativnih ovisnosti:** Koriste se samo `Microsoft.ML` transformacije (FeaturizeText, OneHotEncoding, Concatenate, NormalizeLpNorm) i običan C# za sličnost. Nema Matrix Factorization / LIBMF, pa **radi na macOS-u i svuda** – važno za reprodukciju i demonstraciju.
- **Primjenjivo na restorane:** Atributi (naziv, opis, kuhinja, grad, parking, terasa, ocjena) prirodno se mapiraju u vektore; content-based pristup dobro odgovara domeni gdje su “preferencije” povezane s tim atributima.
- **Moguća proširenja:** Lako se može dodati pravi TF-IDF ručno, eksperimentirati s težinama značajki ili s drugim mjerama sličnosti – sve ostaje u okviru content-based pristupa i pogodno za opis u radu.
