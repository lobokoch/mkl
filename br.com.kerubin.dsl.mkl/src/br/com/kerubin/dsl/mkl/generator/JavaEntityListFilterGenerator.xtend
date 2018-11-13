package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.FilterOperatorEnum
import br.com.kerubin.dsl.mkl.model.Slot

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class JavaEntityListFilterGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	private val final BETWEEN_FROM = 'From'
	private val final BETWEEN_TO = 'To'
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[ entity |
			if (entity.hasListFilter) {
				entity.generateListFilter
				entity.generateListFilterPredicate
				entity.generateListFilterPredicateImpl
			}
		]
	}
	
	def generateListFilter(Entity entity) {
		val basePakage = clientGenSourceFolder
		val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityListFilterName + '.java'
		generateFile(entityFile, entity.generateEntityListFilter)
		entity.imports.clear
	}
	
	def generateListFilterPredicate(Entity entity) {
		val basePakage = serverGenSourceFolder
		val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityListFilterPredicateName + '.java'
		generateFile(entityFile, entity.generateEntityListFilterPredicate)
		entity.imports.clear
	}
	
	def generateListFilterPredicateImpl(Entity entity) {
		val basePakage = serverGenSourceFolder
		val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityListFilterPredicateImplName + '.java'
		generateFile(entityFile, entity.generateEntityListFilterPredicateImpl)
		entity.imports.clear
	}
	
	def CharSequence generateEntityListFilterPredicateImpl(Entity entity) {
		entity.initializeEntityImports
		val varFilter = entity.toEntityListFilterName.toFirstLower
		val qEntity = 'Q' + entity.toEntityName.toFirstUpper
		val varQEntity = 'qEntity'
		val slots = entity.slots.filter[it.hasListFilter]
		
		val package = '''
		package «entity.package»;
		
		'''
		val body = '''
		
		import org.springframework.stereotype.Component;
		import com.querydsl.core.types.Predicate;
		import com.querydsl.core.BooleanBuilder;
		import com.querydsl.core.types.dsl.BooleanExpression;
		
		@Component
		public class «entity.toEntityListFilterPredicateImplName» implements «entity.toEntityListFilterPredicateName» {
			
			@Override
			public Predicate mountAndGetPredicate(«entity.toEntityListFilterName» «varFilter») {
				if («varFilter» == null) {
					return null;
				}
				
				«qEntity» «varQEntity» = «qEntity».«entity.toEntityName.toFirstLower»;
				BooleanBuilder where = new BooleanBuilder();
				
				«slots.map[generateFieldPredicate(varFilter, varQEntity)].join('\r\n')»
				
				return where;
			}
		
		}
		
		'''
		
		package + entity.buildImports + body
	}
	
	def CharSequence buildImports(Entity entity) {
		val imports = '''
		«entity.imports.map[it].join('\r\n')»
		'''
		imports
	}
	
	def CharSequence generateFieldPredicate(Slot slot, String varFilter, String varQEntity) {
		val isMany = isMany(slot)
		val isNotNull = slot.isNotNull
		val isNull = slot.isNull
		val isBetween = slot.isBetween
		
		if (isMany) {
			slot.buildFieldPredicateMany(varFilter, varQEntity)			
		}
		else if (isBetween) {
			slot.buildFieldPredicateBetween(varFilter, varQEntity)	
			
		}
		else if (isNotNull || isNull) {
			slot.buildFieldPredicateBoolean(varFilter, varQEntity)
		}
		
	}
	
	def CharSequence buildFieldPredicateBoolean(Slot slot, String varFilter, String varQEntity) {
		val isNotNull = slot.isNotNull
		val isNull = slot.isNull
		val fieldName = slot.name.toFirstUpper
		
		val isNullStr = 'is' + fieldName + FilterOperatorEnum.IS_NULL.getName.toFirstUpper + '()'
		val isNotNullStr = 'is' + fieldName + FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper + '()'
		
		'''
		«IF isNotNull && isNull»		
		if ( ! («varFilter».«isNullStr» && «varFilter».«isNotNullStr») ) {
					
			if («varFilter».«isNullStr») {
				where.and(«varQEntity».«slot.fieldName».isNull());
			}
			else {
				where.and(«varQEntity».«slot.fieldName».isNotNull());				
			}
			
			if («varFilter».«isNotNullStr») {
				where.and(«varQEntity».«slot.fieldName».isNotNull());
			}
			else {
				where.and(«varQEntity».«slot.fieldName».isNull());				
			}
			
		}
		«ELSEIF isNull»		
		if («varFilter».«isNullStr») {
			where.and(«varQEntity».«slot.fieldName».isNull());
		}
		else {
			where.and(«varQEntity».«slot.fieldName».isNotNull());				
		}
		«ELSEIF isNotNull»		
		if («varFilter».«isNotNullStr») {
			where.and(«varQEntity».«slot.fieldName».isNotNull());
		}
		else {
			where.and(«varQEntity».«slot.fieldName».isNull());				
		}
		«ENDIF»
		'''
	}
	
	def CharSequence buildFieldPredicateBetween(Slot slot, String varFilter, String varQEntity) {
		//slot.ownerEntity.addImport("import org.springframework.util.CollectionUtils;")
		val fieldFrom = 'fieldFrom'
		val fieldTo = 'fieldTo'
		val String[] labels = slot.listFilter.filterOperator?.label?.split(';')
		
		'''
		«slot.toJavaType» «fieldFrom» = «slot.buildMethodGet(varFilter, BETWEEN_FROM)»;
		«slot.toJavaType» «fieldTo» = «slot.buildMethodGet(varFilter, BETWEEN_TO)»;
		
		if («fieldFrom» != null && «fieldTo» != null) {
			«IF slot.isDate»
			if («fieldFrom».isAfter(«fieldTo»)) {
				throw new IllegalArgumentException("Valor de \"«labels.get(0)»\" não pode ser maior do que valor de \"«labels.get(1)»\".");
			}
			«ENDIF»
			
			BooleanExpression between = «varQEntity».«slot.fieldName».between(«fieldFrom», «fieldTo»);
			where.and(between);
		}
		else {
			if («fieldFrom» != null) {
				where.and(«varQEntity».«slot.fieldName».goe(«fieldFrom»));
			}
			else if («fieldTo» != null) {
				where.and(«varQEntity».«slot.fieldName».loe(«fieldTo»));				
			}
		}
		'''
	}
	
	def CharSequence buildFieldPredicateMany(Slot slot, String varFilter, String varQEntity) {
		slot.ownerEntity.addImport("import org.springframework.util.CollectionUtils;")
		
		'''
		if (!CollectionUtils.isEmpty(«varFilter».«slot.buildMethodGet»)) {
			BooleanExpression inExpression = «varQEntity».«slot.name.toFirstLower».in(«varFilter».«slot.buildMethodGet»);
			where.and(inExpression);
		}
		'''
	}
	
	def CharSequence generateEntityListFilterPredicate(Entity entity) {
		entity.initializeEntityImports
		
		'''
		package «entity.package»;
		
		import com.querydsl.core.types.Predicate;
		
		public interface «entity.toEntityListFilterPredicateName» {
			
			Predicate mountAndGetPredicate(«entity.toEntityListFilterName» «entity.toEntityListFilterName.toFirstLower»);
		
		}
		
		'''
	}
	
	def CharSequence generateEntityListFilter(Entity entity) {
		entity.initializeEntityImports
		val slots = entity.slots.filter[it.hasListFilter]
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		public class «entity.toEntityListFilterName» {
		
			«slots.generateFields»
		
		}
		'''
		
		val imports = '''
		«entity.imports.map[it].join('\r\n')»
		'''
		
		package + imports + body 
	}
	
	
	def CharSequence generateFields(Iterable<Slot> slots) {
		'''
		«slots.map[generateField].join('\r\n')»
		
		«slots.map[generateGetterAndSetter].join('\r\n')»
		'''
		
	}
	
	private def boolean isNotNull(Slot slot) {
		slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NOT_NULL) ||
			slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NOT_NULL_IS_NULL)
	} 
	
	private def boolean isNull(Slot slot) {
		slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NULL) ||
			slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NOT_NULL_IS_NULL)
	} 
	
	private def boolean isMany(Slot slot) {
		slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.MANY)
	} 
	
	private def boolean isBetween(Slot slot) {
		slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.BETWEEN)
	} 
	
	def CharSequence generateField(Slot slot) {
		val entity = slot.ownerEntity
		
		if (slot.isDate) {
			entity.addImport("import org.springframework.format.annotation.DateTimeFormat;")
		}
		
		val isNotNull = slot.isNotNull
			
		val isNull = slot.isNull
			
		val isMany = isMany(slot)
		
		val isBetween = slot.isBetween 
		
		'''
		«IF isMany»
		«IF slot.isDate»
		@DateTimeFormat(pattern = "yyyy-MM-dd")
		«ENDIF»
		private java.util.List<«slot.toJavaType»> «slot.name.toFirstLower»;
		«ELSEIF isNotNull && isNull»
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper»;
		
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NULL.getName.toFirstUpper»;
		«ELSEIF isNotNull»
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper»;
		«ELSEIF isNull»
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NULL.getName.toFirstUpper»;
		«ELSEIF isBetween»
		«IF slot.isDate»
		@DateTimeFormat(pattern = "yyyy-MM-dd")
		«ENDIF»
		private «slot.toJavaType» «slot.name.toFirstLower»«BETWEEN_FROM»;
		
		«IF slot.isDate»
		@DateTimeFormat(pattern = "yyyy-MM-dd")
		«ENDIF»
		private «slot.toJavaType» «slot.name.toFirstLower»«BETWEEN_TO»;
		«ENDIF»
		'''
	}
	
	def CharSequence generateGetterAndSetter(Slot slot) {
		
		val isNotNull = slot.isNotNull
			
		val isNull = slot.isNull
			
		val isMany = isMany(slot)
		
		val isBetween = slot.isBetween 
		
		'''
		«IF isMany»
		«slot.getListMethod»
		
		«slot.getSetListMethod»
		«ELSEIF isNotNull && isNull»
		«slot.getGetMethodAsBoolean(FilterOperatorEnum.IS_NOT_NULL.getName())»
		
		«slot.getSetMethodAsBoolean(FilterOperatorEnum.IS_NOT_NULL.getName())»
		
		«slot.getGetMethodAsBoolean(FilterOperatorEnum.IS_NULL.getName())»
		
		«slot.getSetMethodAsBoolean(FilterOperatorEnum.IS_NULL.getName())»
		
		«ELSEIF isNotNull»
		«slot.getGetMethodAsBoolean(FilterOperatorEnum.IS_NOT_NULL.getName())»
				
		«slot.getSetMethodAsBoolean(FilterOperatorEnum.IS_NOT_NULL.getName())»
		«ELSEIF isNull»
		«slot.getGetMethodAsBoolean(FilterOperatorEnum.IS_NULL.getName())»
				
		«slot.getSetMethodAsBoolean(FilterOperatorEnum.IS_NULL.getName())»
		«ELSEIF isBetween»
		«slot.getGetMethod(BETWEEN_FROM)»
		
		«slot.getSetMethod(BETWEEN_FROM)»
		
		«slot.getGetMethod(BETWEEN_TO)»
		
		«slot.getSetMethod(BETWEEN_TO)»
		«ENDIF»
		'''
	}
	
	def void initializeEntityImports(Entity entity) {
		entity.imports.clear
	}
	
	def CharSequence getSlotsEntityImports(Entity entity) {
		'''
		«entity.slots.filter[it.isEntity].map[it | 
			val slotEntity = it.asEntity
			return "import " + slotEntity.package + "." + slotEntity.toEntityName + ";"
			].join('\r\n')»
		'''
	}
	
	
	
}