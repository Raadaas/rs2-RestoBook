using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public class ReservationHistoryService : BaseCRUDService<ReservationHistoryResponse, ReservationHistorySearchObject, Database.ReservationHistory, ReservationHistoryUpsertRequest, ReservationHistoryUpsertRequest>, IReservationHistoryService
    {
        public ReservationHistoryService(eCommerceDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<ReservationHistoryResponse> CreateAsync(ReservationHistoryUpsertRequest request)
        {
            var entity = new Database.ReservationHistory();
            MapInsertToEntity(entity, request);
            _context.Set<Database.ReservationHistory>().Add(entity);

            await BeforeInsert(entity, request);

            await _context.SaveChangesAsync();
            
            // Reload entity with navigation properties
            entity = await _context.ReservationHistories
                .Include(rh => rh.Reservation)
                .Include(rh => rh.ChangedByUser)
                .FirstOrDefaultAsync(rh => rh.Id == entity.Id);
            
            return MapToResponse(entity);
        }

        protected override IQueryable<Database.ReservationHistory> ApplyFilter(IQueryable<Database.ReservationHistory> query, ReservationHistorySearchObject search)
        {
            query = query.Include(rh => rh.Reservation)
                        .Include(rh => rh.ChangedByUser);

            if (search.ReservationId.HasValue)
            {
                query = query.Where(rh => rh.ReservationId == search.ReservationId.Value);
            }

            if (search.ChangedByUserId.HasValue)
            {
                query = query.Where(rh => rh.ChangedByUserId == search.ChangedByUserId.Value);
            }

            if (!string.IsNullOrEmpty(search.StatusChangedTo))
            {
                query = query.Where(rh => rh.StatusChangedTo == search.StatusChangedTo);
            }

            return query;
        }

        protected override ReservationHistoryResponse MapToResponse(Database.ReservationHistory entity)
        {
            if (entity == null)
                return null!;
                
            return new ReservationHistoryResponse
            {
                Id = entity.Id,
                ReservationId = entity.ReservationId,
                StatusChangedFrom = entity.StatusChangedFrom,
                StatusChangedTo = entity.StatusChangedTo,
                ChangedAt = entity.ChangedAt,
                ChangedByUserId = entity.ChangedByUserId,
                ChangedByUserName = entity.ChangedByUser != null ? $"{entity.ChangedByUser.FirstName} {entity.ChangedByUser.LastName}" : string.Empty,
                Notes = entity.Notes
            };
        }
        
        public override async Task<ReservationHistoryResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.ReservationHistories
                .Include(rh => rh.Reservation)
                .Include(rh => rh.ChangedByUser)
                .FirstOrDefaultAsync(rh => rh.Id == id);
                
            if (entity == null)
                return null;
                
            return MapToResponse(entity);
        }
    }
}

