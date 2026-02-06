using Microsoft.ML;
using Microsoft.ML.Data;
using Microsoft.ML.Transforms.Text;
using Microsoft.ML.Transforms;
using System;
using System.Collections.Generic;
using System.Linq;

namespace eCommerce.Services
{
    /// <summary>
    /// Content-based recommender: TF-IDF / one-hot features + cosine similarity.
    /// Cross-platform (no native LIBMF); works on macOS.
    /// </summary>
    public class ContentBasedRestaurantRecommender
    {
        private MLContext _mlContext;
        private ITransformer _transformer = null!;
        private Dictionary<int, float[]> _restaurantVectors = new Dictionary<int, float[]>();
        private int _vectorLength;
        private readonly object _lock = new object();

        public ContentBasedRestaurantRecommender()
        {
            _mlContext = new MLContext(seed: 0);
        }

        /// <summary>
        /// Input row for the ML pipeline: text + categorical + numeric features.
        /// </summary>
        public class RestaurantFeatureInput
        {
            public int RestaurantId { get; set; }
            public string Name { get; set; } = string.Empty;
            public string Description { get; set; } = string.Empty;
            public int CuisineTypeId { get; set; }
            public int CityId { get; set; }
            public float HasParking { get; set; }
            public float HasTerrace { get; set; }
            public float IsKidFriendly { get; set; }
            public float AverageRating { get; set; }
        }

        /// <summary>
        /// Builds the feature pipeline and fits it on the given restaurants.
        /// Pipeline: FeaturizeText (Name, Description) + OneHotEncoding (Cuisine, City) + Concatenate + L2 normalize.
        /// </summary>
        public void BuildFromRestaurants(IEnumerable<RestaurantFeatureInput> restaurants)
        {
            lock (_lock)
            {
                var list = restaurants.ToList();
                if (list.Count == 0)
                {
                    _restaurantVectors = new Dictionary<int, float[]>();
                    return;
                }

                var dataView = _mlContext.Data.LoadFromEnumerable(list);

                // 1) Text featurization (bag-of-words / TF-IDF style) for Name and Description
                var nameFeatures = _mlContext.Transforms.Text.FeaturizeText("NameFeatures", "Name");
                var descFeatures = _mlContext.Transforms.Text.FeaturizeText("DescFeatures", "Description");

                // 2) One-hot encoding for categorical
                var cuisineOneHot = _mlContext.Transforms.Categorical.OneHotEncoding(
                    new[] { new InputOutputColumnPair("CuisineOneHot", "CuisineTypeId") });
                var cityOneHot = _mlContext.Transforms.Categorical.OneHotEncoding(
                    new[] { new InputOutputColumnPair("CityOneHot", "CityId") });

                // 3) Concatenate all into one feature vector
                var concat = _mlContext.Transforms.Concatenate("Features",
                    "NameFeatures", "DescFeatures", "CuisineOneHot", "CityOneHot",
                    "HasParking", "HasTerrace", "IsKidFriendly", "AverageRating");

                // 4) L2 normalize so cosine similarity = dot product
                var normalize = _mlContext.Transforms.NormalizeLpNorm("Features", "Features", norm: Microsoft.ML.Transforms.LpNormNormalizingEstimatorBase.NormFunction.L2);

                var pipeline = nameFeatures
                    .Append(descFeatures)
                    .Append(cuisineOneHot)
                    .Append(cityOneHot)
                    .Append(concat)
                    .Append(normalize);

                _transformer = pipeline.Fit(dataView);
                var transformed = _transformer.Transform(dataView);

                _restaurantVectors = ExtractVectorsById(transformed, "RestaurantId", "Features");
                _vectorLength = _restaurantVectors.Values.FirstOrDefault()?.Length ?? 0;
            }
        }

        private static int GetColumnIndex(DataViewSchema schema, string name)
        {
            for (int i = 0; i < schema.Count; i++)
                if (schema[i].Name == name) return i;
            return -1;
        }

        private static Dictionary<int, float[]> ExtractVectorsById(IDataView dataView, string idColumnName, string vectorColumnName)
        {
            var result = new Dictionary<int, float[]>();
            int idIdx = GetColumnIndex(dataView.Schema, idColumnName);
            int vecIdx = GetColumnIndex(dataView.Schema, vectorColumnName);
            if (idIdx < 0 || vecIdx < 0) return result;

            var idCol = dataView.Schema[idIdx];
            var vecCol = dataView.Schema[vecIdx];
            using var cursor = dataView.GetRowCursor(new[] { idCol, vecCol });
            var idGetter = cursor.GetGetter<int>(idCol);
            var vecGetter = cursor.GetGetter<VBuffer<float>>(vecCol);
            int id = 0;
            VBuffer<float> vec = default;

            while (cursor.MoveNext())
            {
                idGetter(ref id);
                vecGetter(ref vec);
                var dense = vec.DenseValues().ToArray();
                result[id] = dense;
            }
            return result;
        }

        /// <summary>
        /// Builds the user profile vector as the L2-normalized average of vectors of restaurants the user liked.
        /// </summary>
        public float[]? GetUserProfileVector(IEnumerable<int> likedRestaurantIds)
        {
            lock (_lock)
            {
                var ids = likedRestaurantIds.ToList();
                if (ids.Count == 0 || _vectorLength == 0) return null;

                var vectors = ids
                    .Where(id => _restaurantVectors.TryGetValue(id, out _))
                    .Select(id => _restaurantVectors[id])
                    .ToList();
                if (vectors.Count == 0) return null;

                var avg = new float[_vectorLength];
                foreach (var v in vectors)
                {
                    for (int i = 0; i < Math.Min(v.Length, _vectorLength); i++)
                        avg[i] += v[i];
                }
                for (int i = 0; i < avg.Length; i++)
                    avg[i] /= vectors.Count;

                return NormalizeL2(avg);
            }
        }

        /// <summary>
        /// Cosine similarity between two L2-normalized vectors = dot product.
        /// </summary>
        public static float CosineSimilarity(ReadOnlySpan<float> a, ReadOnlySpan<float> b)
        {
            if (a.Length != b.Length || a.Length == 0) return 0f;
            float dot = 0f;
            for (int i = 0; i < a.Length; i++)
                dot += a[i] * b[i];
            return dot;
        }

        private static float[] NormalizeL2(float[] v)
        {
            float norm = 0f;
            for (int i = 0; i < v.Length; i++)
                norm += v[i] * v[i];
            norm = (float)Math.Sqrt(norm);
            if (norm < 1e-9f) return v;
            var r = new float[v.Length];
            for (int i = 0; i < v.Length; i++)
                r[i] = v[i] / norm;
            return r;
        }

        /// <summary>
        /// Returns top-N restaurant IDs by cosine similarity between user profile and candidate restaurant vectors.
        /// </summary>
        public IReadOnlyList<int> GetTopN(float[]? userProfileVector, IEnumerable<int> candidateRestaurantIds, int n)
        {
            lock (_lock)
            {
                var candidates = candidateRestaurantIds.ToList();
                if (n <= 0 || candidates.Count == 0) return Array.Empty<int>();

                if (userProfileVector == null || userProfileVector.Length != _vectorLength)
                {
                    // No profile: return first N candidates (caller can sort by rating instead)
                    return candidates.Take(n).ToList();
                }

                var scored = candidates
                    .Where(id => _restaurantVectors.TryGetValue(id, out _))
                    .Select(id => new { Id = id, Score = CosineSimilarity(userProfileVector, _restaurantVectors[id]) })
                    .OrderByDescending(x => x.Score)
                    .Take(n)
                    .Select(x => x.Id)
                    .ToList();

                return scored;
            }
        }

        public bool IsBuilt => _restaurantVectors.Count > 0;
        public int VectorLength => _vectorLength;
    }
}
