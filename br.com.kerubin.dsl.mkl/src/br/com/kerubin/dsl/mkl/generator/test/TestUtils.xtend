package br.com.kerubin.dsl.mkl.generator.test

import br.com.kerubin.dsl.mkl.generator.ServiceBoosterImpl
import br.com.kerubin.dsl.mkl.model.BooleanType
import br.com.kerubin.dsl.mkl.model.ByteType
import br.com.kerubin.dsl.mkl.model.DateTimeType
import br.com.kerubin.dsl.mkl.model.DateType
import br.com.kerubin.dsl.mkl.model.DoubleType
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.IntegerType
import br.com.kerubin.dsl.mkl.model.MoneyType
import br.com.kerubin.dsl.mkl.model.Service
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.SmallintType
import br.com.kerubin.dsl.mkl.model.StringType
import br.com.kerubin.dsl.mkl.model.TimeType
import br.com.kerubin.dsl.mkl.model.UUIDType
import java.util.List
import java.util.Random

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

class TestUtils {
	
	public static val ACTUAL = 'actual'
	public static val IGNORED_FIELDS = 'IGNORED_FIELDS'
	public static val GET_NEXT_DATE = 'getNextDate()'
	public static val GENERATE_RANDOM_STRING = 'generateRandomString'
	public static val GET_RANDOM_ITEMS_OF = 'getRandomItemsOf'
	
	public static val FIRST_RECORD_VAR = 'firstRecord'
	public static val LAST_RECORD_VAR = 'lastRecord'
	public static val COUNT_VAR = 'count'
	public static val TEST_DATA = 'testData'
	
	def static buildEntityManagerFlush() {
		'''
		em.flush();
		'''
	}
	
	def static CharSequence buildAssertThatActualIsNotNull() {
		ACTUAL.buildAssertThatIsNotNull
	}
	
	def static CharSequence buildAssertThatIsEqualTo(String actual, String expected) {
		'''
		assertThat(«actual»).isEqualTo(«expected»);
		'''
	}
	
	def static CharSequence buildAssertThatIsNotNull(String varName) {
		'''
		assertThat(«varName»).isNotNull();
		'''
	}
	
	def static CharSequence buildAssertThatIsNull(String varName) {
		'''
		assertThat(«varName»).isNull();
		'''
	}
	
	def static CharSequence buildAssertThatEntityAsVarIdIsNotNull(Entity entity, String varName) {
		val getField = entity.id.buildMethodGet
		
		'''
		assertThat(«varName».«getField»).isNotNull();
		'''
	}
	
	def static CharSequence buildAssertThatEntitySlotIdIsNotNull(Slot slot, String varName) {
		val entity = slot.asEntity
		val idGetMethod = entity.id.buildMethodGet
		
		'''
		assertThat(«varName».«slot.buildMethodGet».«idGetMethod»).isNotNull();
		'''
	}
	
	def static CharSequence getIdAsString(Entity entity) {
		'''"«entity.id.fieldName»"'''
	}
	
	def static CharSequence generateIgnoredFieldsConstant(Entity entity) {
		
		'''
		private static final String[] «IGNORED_FIELDS» = { «entity.getIgnoredFields» };
		'''
	}
	
	def static CharSequence getIgnoredFields(Entity entity) {
		val auditinFields = ServiceBoosterImpl.ENTITY_AUDITING_FIELDS.map['"' + it + '"'].join(', ')
		
		'''«entity.getIdAsString»«IF entity.isAuditing», «auditinFields»«ENDIF»'''
	}
	
	def static CharSequence buildAssertThatEntityAsVarIsEqualToIgnoringGivenFields(Entity entity, String varName) {
		val fieldName = entity.fieldName
		
		'''
		assertThat(«varName»).isEqualToIgnoringGivenFields(«fieldName», «IGNORED_FIELDS»);
		'''
	}
	
	def static CharSequence buildAssertThatIsEqualToIgnoringGivenFields(Slot slot, String varName) {
		val entity = slot.ownerEntity
		val getField = slot.buildMethodGet
		val fieldName = entity.fieldName
		
		'''
		assertThat(«varName».«getField»).isEqualToIgnoringGivenFields(«fieldName».«getField», «IGNORED_FIELDS»);
		'''
	}
	
	def static buildAssertEntityFKsIsEqualToIgnoringGivenFields(Slot slot, String varName) {
		'''
		
		«slot.buildAssertThatEntitySlotIdIsNotNull(varName)»
		«slot.buildAssertThatIsEqualToIgnoringGivenFields(varName)»
		
		'''
	}
	
	def static buildEntityCheckActualWithDTO(Entity entity) {
		'''
		«buildAssertThatActualIsNotNull»
		«entity.buildAssertThatEntityAsVarIdIsNotNull(ACTUAL)»
		«entity.buildAssertThatEntityAsVarIsEqualToIgnoringGivenFields(ACTUAL)»
		
		«entity.slots.filter[it.isEntity].map[it.buildAssertEntityFKsIsEqualToIgnoringGivenFields(ACTUAL)].join»
		
		'''
	}
	
	def static CharSequence buildEntityToDTOAsActual(Entity entity) {
		entity.buildEntityToDTO(ACTUAL)
	}
	
	def static CharSequence buildEntityToDTO(Entity entity, String targetVar) {
		val entityVar = entity.toEntityName.toFirstLower
		val entityDTOName = entity.toEntityDTOName
		val entityDTOVar = entity.toEntityDTOName.toFirstLower
		val toDTO = 'convertEntityToDto'
		
		'''
		«entityDTOName» «targetVar» = «entityDTOVar»DTOConverter.«toDTO»(«entityVar»);
		'''
	}
	
	def static CharSequence buildServiceCreateFromDTO(Entity entity) {
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val entityDTOVar = entity.toEntityDTOName.toFirstLower
		val entityServiceVar = entity.toServiceName.toFirstLower
		val toEntity = 'convertDtoToEntity'
		
		'''
		«entityName» «entityVar» = «entityServiceVar».create(«entityDTOVar»DTOConverter.«toEntity»(«entityDTOVar»));
		'''
	}
	
	def static CharSequence buildNewEntityDTOVar(Entity entity) {
		val name = entity.name
		val fieldName = entity.fieldName
		'''«name» «fieldName» = new «name»();'''
	}
	
	def static getEntityParamFieldName(Entity entity) {
		entity.name.toFirstLower + "EntityParam"
	}
	
	def static CharSequence buildNewEntityVar(Entity entity) {
		val name = entity.toEntityName
		val fieldName = entity.getEntityParamFieldName
		'''«name» «fieldName» = new«name»();'''
	}
	
	def static CharSequence buildNewOldEntityVar(Entity entity) {
		val name = entity.toEntityName
		val nameUpper = name.toFirstUpper
		
		'''«name» old«nameUpper» = new«nameUpper»();'''
	}
	
	def static CharSequence buildGetEntityIdVarFromOldVar(Entity entity) {
		val name = entity.toEntityName
		val nameUpper = name.toFirstUpper
		val id = entity.id
		
		'''«id.toJavaType» id = old«nameUpper».«id.getMethod2»;'''
	}
	
	def static CharSequence buildNewEntityWithVar(Entity entity) {
		val name = entity.toEntityName
		val fieldName = entity.entityFieldName
		'''«name» «fieldName» = new «name»();'''
	}
	
	def static CharSequence buildNewEntityLookupResultVar(Slot slot) {
		val entity = slot.asEntity
		val name = entity.toEntityLookupResultDTOName
		val fieldName = slot.fieldName
		val entityFieldName = entity.entityParamFieldName
		// PlanoContaLookupResult planoContas = new PlanoContaLookupResult(planoContaEntity);
		'''«name» «fieldName» = new«name»(«entityFieldName»);'''
	}
	
	def static CharSequence buildNewEntityLookupResultWithVar(Slot slot) {
		val entity = slot.asEntity
		val name = entity.toEntityLookupResultDTOName
		val fieldName = slot.fieldName
		val entityFieldName = entity.entityFieldName
		// PlanoContaLookupResult planoContas = new PlanoContaLookupResult(planoContaEntity);
		'''«name» «fieldName» = new «name»(«entityFieldName»);'''
	}
	
	
	def static CharSequence buildNewEntityMethod(Entity entity) {
		var name = entity.toEntityName
		val fieldName = entity.entityFieldName
		
		val slots = entity.slots.filter[
			val result = !it.isAuditingSlot && !(it.isId && !entity.isExternalEntity)
			
			return result
		]
		
		'''
		
		protected «name» new«name»() {
			«entity.buildNewEntityWithVar»
			
			«slots.filter[!it.isAuditingSlot].map[generateSetterForTest].join»
			
			«fieldName» = em.persistAndFlush(«fieldName»);
			
			return «fieldName»;
		}
		'''
	}
	
	def static CharSequence buildNewEntityLookupResultMethod(Entity entity) {
		val lookupResultName = entity.toEntityLookupResultDTOName
		val entityFieldName = entity.entityFieldName
		val fieldName = entity.fieldName
		val slots = entity.getEntityLookupResultSlots
		
		'''
		
		protected «lookupResultName» new«lookupResultName»(«entityFieldName.toFirstUpper» «entityFieldName») {
			«lookupResultName» «fieldName» = new «lookupResultName»();
			
			«slots.map[generateSetterForLookupResult].join»
			
			return «fieldName»;
		}
		'''
	}
	
	def static CharSequence generateSetterForLookupResult(Slot slot) {
		val entity = slot.ownerEntity
		val slotName = slot.name.toFirstUpper
		
		'''
		«entity.fieldName».set«slotName»(«entity.entityFieldName».get«slotName»());
		'''
	}
	
	def static CharSequence generateSetterForTest(Slot slot) {
		val entity = slot.ownerEntity
		
		'''
		«entity.entityFieldName».set«slot.name.toFirstUpper»(«slot.generateRandomTestValueForDTO»);
		'''
	}
	
	def static CharSequence generateSettersForDTO(Entity entity) {
		return entity.generateSettersForDTO(null)
	}
	
	def static CharSequence generateSettersForDTO(Entity entity, List<Slot> excludedSlots) {
		var slots = entity.slots.filter[!it.isAuditingSlot]
		
		if (excludedSlots !== null) {
			slots = slots.filter[ slot | !excludedSlots.exists[it === slot]]
		}
		
		'''
		«slots.map[generateSetterForDTO].join»
		'''
	}
	
	def static CharSequence generateSetterForDTO(Slot slot) {
		val entity = slot.ownerEntity
		val fieldName = entity.fieldName
		
		'''
		«IF slot.isEntity»
		
		«slot.asEntity.buildNewEntityVar»
		«slot.buildNewEntityLookupResultVar»
		«fieldName».set«slot.name.toFirstUpper»(«slot.fieldName»);
		
		«ELSE»
		«fieldName».set«slot.name.toFirstUpper»(«slot.generateRandomTestValueForDTO»);
		«ENDIF»
		'''
	}
	
	def static CharSequence generateRandomTestValueForDTO(Slot slot) {
		val basicType = slot.basicType
		if (basicType instanceof StringType) {
			'''«GENERATE_RANDOM_STRING»(«slot.length»)'''
		}
		else if (basicType instanceof IntegerType) {
			val ran = new Random();
			ran.nextInt + ''
		}
		else if (basicType instanceof SmallintType) {
			val ran = new Random();
			ran.nextInt(Short.MAX_VALUE) + ''
		}
		else if (basicType instanceof DoubleType) {
			val ran = new Random();
			ran.nextDouble + ''
		}
		else if (basicType instanceof MoneyType) {
			val ran = new Random();
			val a = ran.nextInt(Short.MAX_VALUE)
			val b = ran.nextInt(Short.MAX_VALUE)
			'''new java.math.BigDecimal("«a».«b»")'''
		}
		else if (basicType instanceof BooleanType) {
			val ran = new Random();
			if (slot.hasDefaultValue) slot.defaultValue else ran.nextBoolean + ''
		}
		else if (basicType instanceof DateType) {
			'''«GET_NEXT_DATE»'''
		}
		else if (basicType instanceof TimeType) {
			'''java.time.LocalTime.now()'''
		}
		else if (basicType instanceof DateTimeType) {
			'''java.time.LocalDateTime.now()'''
		}
		else if (basicType instanceof UUIDType) {
			'''java.util.UUID.randomUUID()'''
		}
		else if (basicType instanceof ByteType) {
			'''"Unit tests".getBytes()'''
		}
		else {
			if (slot.isEnum) {
				val asEnum = slot.asEnum
				if (asEnum.hasDefault) {
					val result = asEnum.items.get(asEnum.defaultIndex).name
					return asEnum.name + '.' + result.toString
				} else {
					val ran = new Random();
					val index = ran.nextInt(asEnum.items.size)
					val result = asEnum.items.get(index).name
					return asEnum.name + '.' + result.toString
				} 
			} 
			else if (slot.isEntity && slot.ownerEntity.isNotSameName(slot.asEntity)) {
				'''new«slot.asEntity.entityFieldName.toFirstUpper»()'''
			}
			else {
				'''null'''
			}
		}
		
	}
	
	def static void resolveEntityImports(Entity entitySource, Entity entityTarget) {
		entitySource.resolveSlotsEntityImports(entityTarget)
		entitySource.resolveEntityDTOLookupResultImports(entityTarget)
		entitySource.resolveEntityEnumImports(entityTarget)
	}
	
	def static void resolveSlotsEntityImports(Entity entitySource, Entity entityTarget) {
		entitySource.slots.filter[isEntity].forEach[
			val slotEntity = it.asEntity
			entityTarget.addImport('import ' + slotEntity.package + '.' + slotEntity.toEntityName + ';')
		]
	}
	
	def static void resolveEntityDTOLookupResultImports(Entity entitySource, Entity entityTarget) {
		entitySource.slots.filter[isDTOLookupResult].forEach[
			val slotEntity = it.asEntity
			entityTarget.addImport('import ' + slotEntity.package + '.' + slotEntity.toEntityLookupResultDTOName + ';')
		]
	}
	
	def static void resolveEntityEnumImports(Entity entitySource, Entity entityTarget) {
		entitySource.slots.filter[isEnum].forEach[
			val asEnum = it.asEnum
			entityTarget.addImport('import ' + asEnum.enumPackage + ';')
		]
	}
	
	def static void resolveEntityImports(Entity entity) {
		entity.resolveSlotsEntityImports
		entity.resolveEntityDTOLookupResultImports
		entity.resolveEntityEnumImports
		
	}
	
	def static void resolveSlotsEntityImports(Entity entity) {
		entity.slots.filter[isEntity].forEach[
			val slotEntity = it.asEntity
			entity.addImport('import ' + slotEntity.package + '.' + slotEntity.toEntityName + ';')
		]
	}
	
	def static void resolveEntityDTOLookupResultImports(Entity entity) {
		entity.slots.filter[isDTOLookupResult].forEach[
			val slotEntity = it.asEntity
			entity.addImport('import ' + slotEntity.package + '.' + slotEntity.toEntityLookupResultDTOName + ';')
		]
	}
	
	def static void resolveEntityEnumImports(Entity entity) {
		entity.slots.filter[isEnum].forEach[
			val asEnum = it.asEnum
			entity.addImport('import ' + asEnum.enumPackage + ';')
		]
	}
	
	def static toRepositoryNameForTest(Entity entity) {
		var name = entity.name.toFirstUpper 
		name += "TestRepository"
		name
	}
	
	def static String toServiceEntityBaseTestClassName(Service service) {
		service.domain.toCamelCase + service.name.toCamelCase + "BaseEntityTest"
	}
	
	def static String toServiceEntityBaseTestConfigClassName(Service service) {
		val baseName = service.toServiceEntityBaseTestClassName
		val name = baseName + 'Config'
		name
	}
	
	def static CharSequence generateEntityManagerFind(Entity entity) {
		val expected = 'expected'
		entity.generateEntityManagerFind(expected)
	}
	
	def static CharSequence generateEntityManagerFind(Entity entity, String varName) {
		val entityName = entity.toEntityName
		val id = entity.id
		
		'''
		«varName» = em.find(«entityName».class, «id.fieldName»);
		'''		
	}
	
	def static CharSequence generateServiceDelete(Entity entity) {
		val idVar = 'id'
		
		'''
		«entity.fieldName»Service.delete(«idVar»);
		'''		
	}
	
	def static CharSequence generateNewEntityListFilterVar(Entity entity) {
		val name = entity.toDtoName
		
		'''
		// Creates a list filter for entity «name».
		«name»ListFilter listFilter = new «name»ListFilter();
		'''
	}
	
	def static CharSequence generateGetRandomItemsOf(Entity entity, int resultSize) {
		val entityName = entity.toEntityName
		
		'''
		// Extracts «resultSize» records of «entityName» randomly from «TEST_DATA».
		final int resultSize = «resultSize»;
		List<«entityName»> filterTestData = «GET_RANDOM_ITEMS_OF»(«TEST_DATA», resultSize);
		'''
		
	}
	
	def static CharSequence generateAndSetListFilterToSlot(Slot slot) {
		
		if (slot === null) {
			val result = '''
			// generateAndSetListFilterToSlot = null
			'''
			
			return result
		}
		
		val entity = slot.ownerEntity
		val fieldName = slot.fieldName
		val fieldUpper = fieldName.toFirstUpper
		val entityName = entity.toEntityName
		
		'''
		// Extracts a list with only «entityName».«fieldName» fields and configure this list as a filter.
		List<«slot.toJavaType»> «fieldName»ListFilter = filterTestData.stream().map(«entityName»::get«fieldUpper»).collect(Collectors.toList());
		listFilter.set«fieldUpper»(«fieldName»ListFilter);
		'''
	}
	
	def static CharSequence generateCollectSlotTestData(Slot slot, String dataSource) {
		val entity = slot.ownerEntity
		val fieldName = slot.fieldName
		val fieldUpper = fieldName.toFirstUpper
		val entityName = entity.toEntityName
		
		'''
		// Extracts a list with only «entityName».«fieldName» fields.
		List<«slot.toJavaType»> «slot.generateCollectedSlotTestDataVar» = «dataSource».stream().map(«entityName»::get«fieldUpper»).collect(Collectors.toList());
		'''
	}
	
	static def generateCollectedSlotTestDataVar(Slot slot) {
		slot.fieldName + 'TestDataList'
	}
	
	def static CharSequence generateSortAscCollectedSlotTestData(Slot slot) {
		'''
		// Sort «slot.fieldName» in ascending order.
		Collections.sort(«slot.generateCollectedSlotTestDataVar»);
		'''
	}
	
	def static CharSequence generatePageableAsc(int pageIndex, int pageSize, Slot slot) {
		generatePageable(pageIndex, pageSize, slot.fieldName, /*isASC=*/true)
	}
	
	def static CharSequence generatePageableDesc(int pageIndex, int pageSize, Slot slot) {
		generatePageable(pageIndex, pageSize, slot.fieldName, /*isASC=*/false)
	}
	
	def static CharSequence generatePageable(int pageIndex, int pageSize, String orderByField, boolean isASC) {
		val sort = isASC.getOrderBy
		
		'''
		// Generates a pageable configuration, with sorting.
		Sort sort = Sort.by("«orderByField»").«sort»(); // select ... order by «orderByField» «sort»
		int pageIndex = «pageIndex»; // First page starts at index zero.
		int size = «pageSize»; // Max of «pageSize» records per page.
		Pageable pageable = PageRequest.of(pageIndex, size, sort);
		'''
	}
	
	def static CharSequence generatePageableWithoutSort(int pageIndex, int pageSize) {
		'''
		// Generates a pageable configuration, without sorting.
		int pageIndex = «pageIndex»; // First page starts at index zero.
		int size = «pageSize»; // Max of «pageSize» records per page.
		Pageable pageable = PageRequest.of(pageIndex, size);
		'''
	}
	
	def static String getOrderBy(boolean isASC) {
		val result = if (isASC) 'ascending' else 'descending'
		result
	}
	
	def static CharSequence generateCallServiceList(Entity entity) {
		val entityName = entity.toEntityName
		val entityFieldName = entity.fieldName
		
		'''
		// Call service list method.
		Page<«entityName»> page = «entityFieldName»Service.list(listFilter, pageable);
		'''
	}
	
	def static CharSequence generatePageContentMapToPageResult(Entity entity) {
		val name = entity.toEntityDTOName
		val entityFieldName = entity.fieldName
		
		'''
		// Converts found entities to DTOs and mount the result page.
		List<«name»> content = page.getContent().stream().map(it -> «entityFieldName»DTOConverter.convertEntityToDto(it)).collect(Collectors.toList());
		PageResult<«name»> pageResult = new PageResult<>(content, page.getNumber(), page.getSize(), page.getTotalElements());
		'''
	}
	
	def static CharSequence assertThatSlotListFilterResultContent(Slot slot, int resultSize) {
		val fieldName = slot.fieldName
		
		'''
		// Asserts that result has size «resultSize», in any order and has only rows with «fieldName»ListFilter elements based on «fieldName» field.
		assertThat(pageResult.getContent())
		.hasSize(«resultSize»)
		.extracting(«slot.toLambdaGetMethod»)
		.containsExactlyInAnyOrderElementsOf(«fieldName»ListFilter);
		'''
	}
	
	def static CharSequence assertThatSortSlotResultContent(Slot slot, int size) {
		
		'''
		// Asserts that result has size «size» in a specific order.
		assertThat(pageResult.getContent())
		.hasSize(«size»)
		.extracting(«slot.toLambdaGetMethod»)
		.containsExactlyElementsOf(«slot.generateCollectedSlotTestDataVar»);
		'''
	}
	
	def static CharSequence assertThatSortSlotResultContent() {
		
		'''
		
		'''
	}
	
	def static CharSequence generateAssertThatPageResult(int totalPages, int elements, int totalElements) {
		
		'''
		// Asserts some page result elements.
		assertThat(pageResult.getNumber()).isEqualTo(pageIndex);
		assertThat(pageResult.getNumberOfElements()).isEqualTo(«elements»);
		assertThat(pageResult.getTotalElements()).isEqualTo(«totalElements»);
		assertThat(pageResult.getTotalPages()).isEqualTo(«totalPages»);
		'''
	}
	
	def static CharSequence generateFieldLastDate() {
		'''
		protected LocalDate lastDate = LocalDate.now();
		'''
	}
	
	def static CharSequence generateMethodGetNextDate() {
		
		'''
		protected LocalDate getNextDate() {
			if (lastDate == null) {
				lastDate = LocalDate.now();
			}
			LocalDate result = LocalDate.of(lastDate.getYear(), lastDate.getMonth(), lastDate.getDayOfMonth());
			lastDate = lastDate.plusDays(1);
			
			return result;
			
		}
		'''
	}
	
	def static CharSequence generateCallResetNextDate() {
		'''
		// Reset lastDate field to start LocalDate fields with today in this test. 
		resetNextDate();
		'''
	}
	
	def static CharSequence generateMethodResetNextDate() {
		
		'''
		protected void resetNextDate() {
			lastDate = null;
		}
		'''
	}
	
	def static CharSequence generateMethodGenerateRandomString() {
		'''
		protected String generateRandomString(int maxLength) {
			int length = (maxLength > 30) ? 30 : maxLength; 
			String chars = RandomStringUtils.randomAlphabetic(length - 1) + " ";
			String value = RandomStringUtils.random(length, chars).trim();
			
			// Must remove white spaces in the begining.
			int attempts= 0;
			while (value.length() < length && (attempts < Integer.MAX_VALUE) ) {
				attempts++;
				value = RandomStringUtils.random(length, chars).trim();
			} 
			return value;
		}
		'''
	}
	
	def static CharSequence generateMethodGetRandomItemsOf() {
		'''
		protected <T> List<T> getRandomItemsOf(List<T> list, int size) {
			if (list == null || size <= 0) {
				return Collections.emptyList();
			}
			List<T> result = new ArrayList<>();
			Random ran = new Random();
			int bound = list.size();
			int attempts = 0;
			do {
				attempts++;
				int index = ran.nextInt(bound);
				T item = list.get(index);
				if (!result.contains(item)) {
					result.add(item);
				}
			} while (result.size() < size && (attempts < Integer.MAX_VALUE));
			
			return result;
			
		}
		'''
	}
	
	def static CharSequence generateInicializeCreateDataForEntity(Entity entity) {
		entity.generateInicializeCreateDataForEntity(1, 33)
	}
	
	def static CharSequence generateInicializeCreateDataForEntity(Entity entity, int lastRecord) {
		entity.generateInicializeCreateDataForEntity(1, lastRecord)
	}
	
	def static CharSequence generateInicializeCreateDataForEntity(Entity entity, int firstRecord, int lastRecord) {
		val entityName = entity.toEntityName
		
		'''
		// Generate «lastRecord» records of data for «entityName» for this test.
		final int «FIRST_RECORD_VAR» = «firstRecord»;
		final int «LAST_RECORD_VAR» = «lastRecord»;
		List<«entityName»> «TEST_DATA» = new ArrayList<>();
		for (int i = «FIRST_RECORD_VAR»; i <= «LAST_RECORD_VAR»; i++) {
			«TEST_DATA».add(new«entityName»());
		}
		
		// Check if «lastRecord» records of «entityName» was generated.
		long «COUNT_VAR» = «entity.toRepositoryName.toFirstLower».count();
		«COUNT_VAR.buildAssertThatIsEqualTo(LAST_RECORD_VAR)»
		'''
	}
	
}