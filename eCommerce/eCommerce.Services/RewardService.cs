using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public class RewardService : BaseCRUDService<RewardResponse, RewardSearchObject, Database.Reward, RewardUpsertRequest, RewardUpsertRequest>, IRewardService
    {
        public RewardService(eCommerceDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Database.Reward> ApplyFilter(IQueryable<Database.Reward> query, RewardSearchObject search)
        {
            if (search.RestaurantId.HasValue)
                query = query.Where(r => r.RestaurantId == search.RestaurantId.Value);

            if (!string.IsNullOrEmpty(search.Title))
                query = query.Where(r => r.Title.Contains(search.Title));

            if (!string.IsNullOrEmpty(search.FTS))
                query = query.Where(r => r.Title.Contains(search.FTS) || (r.Description != null && r.Description.Contains(search.FTS)));

            if (search.IsActive.HasValue)
                query = query.Where(r => r.IsActive == search.IsActive.Value);

            return query;
        }

        protected override RewardResponse MapToResponse(Database.Reward entity)
        {
            var response = _mapper.Map<RewardResponse>(entity);
            response.TimesClaimed = _context.UserRewards.Count(ur => ur.RewardId == entity.Id);
            response.CanRedeem = false;
            return response;
        }

        protected override async Task BeforeInsert(Database.Reward entity, RewardUpsertRequest request)
        {
            entity.CreatedAt = DateTime.UtcNow;
            await Task.CompletedTask;
        }
    }
}
