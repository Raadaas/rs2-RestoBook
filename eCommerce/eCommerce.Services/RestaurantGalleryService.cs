using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Services.Database;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public class RestaurantGalleryService : IRestaurantGalleryService
    {
        private readonly eCommerceDbContext _context;

        public RestaurantGalleryService(eCommerceDbContext context)
        {
            _context = context;
        }

        public async Task<IReadOnlyList<RestaurantGalleryResponse>> GetByRestaurantIdAsync(int restaurantId)
        {
            var items = await _context.RestaurantGalleries
                .AsNoTracking()
                .Where(rg => rg.RestaurantId == restaurantId)
                .OrderBy(rg => rg.DisplayOrder)
                .ThenBy(rg => rg.UploadedAt)
                .ToListAsync();

            return items.Select(rg => new RestaurantGalleryResponse
            {
                Id = rg.Id,
                RestaurantId = rg.RestaurantId,
                ImageUrl = rg.ImageUrl,
                ImageType = rg.ImageType,
                DisplayOrder = rg.DisplayOrder,
                UploadedAt = rg.UploadedAt
            }).ToList();
        }

        public async Task<RestaurantGalleryResponse> InsertAsync(RestaurantGalleryInsertRequest request)
        {
            var entity = new RestaurantGallery
            {
                RestaurantId = request.RestaurantId,
                ImageUrl = request.ImageUrl,
                ImageType = request.ImageType,
                DisplayOrder = request.DisplayOrder,
                UploadedAt = DateTime.UtcNow
            };
            _context.RestaurantGalleries.Add(entity);
            await _context.SaveChangesAsync();

            return new RestaurantGalleryResponse
            {
                Id = entity.Id,
                RestaurantId = entity.RestaurantId,
                ImageUrl = entity.ImageUrl,
                ImageType = entity.ImageType,
                DisplayOrder = entity.DisplayOrder,
                UploadedAt = entity.UploadedAt
            };
        }

        public async Task DeleteAsync(int id)
        {
            var entity = await _context.RestaurantGalleries.FindAsync(id);
            if (entity == null)
                throw new InvalidOperationException("Gallery image not found.");
            _context.RestaurantGalleries.Remove(entity);
            await _context.SaveChangesAsync();
        }
    }
}
