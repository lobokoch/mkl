package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class JavaEntityRepositoryGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.filter[it.canGenerateRepository].forEach[generateRepository]
	}
	
	def generateRepository(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toRepositoryName + '.java'
		generateFile(fileName, entity.generateEntityRepository)
	}
	
	def CharSequence generateEntityRepository(Entity entity) {
		entity.imports.clear
		
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val autoCompleteSlots = entity.slots.filter[it.hasAutoComplete || (entity.hasEntityVersion && it.name.toLowerCase == 'version')]
		val hasAutoComplete = !autoCompleteSlots.isEmpty
		
		val findBySlots = entity.slots.filter[it.hasRepositoryFindBy]
		val findBy = findBySlots.map[it.generateRepositoryFindByForEntity].join
		
		// Due deleteInBulk
		entity.addImport('import org.springframework.data.jpa.repository.Query;')
		entity.addImport('import org.springframework.data.jpa.repository.Modifying;')
		entity.addImport('import org.springframework.transaction.annotation.Transactional;')
		
		if (hasAutoComplete) {
			entity.addImport('import java.util.Collection;')
		}
		
		val isBaseRepository = entity.isBaseRepository
		if (!isBaseRepository) {
			entity.addImport('import org.springframework.transaction.annotation.Transactional;')
		}
		
		'''
		package «entity.package»;
		
		import org.springframework.data.jpa.repository.JpaRepository;
		import org.springframework.data.querydsl.QuerydslPredicateExecutor;
		«entity.imports.map[it].join('\r\n')»
		«IF hasAutoComplete»
		import org.springframework.data.repository.query.Param;
		«ENDIF»
		«IF isBaseRepository»
		import org.springframework.data.repository.NoRepositoryBean;
		
		@NoRepositoryBean
		«ELSE»
		
		@Transactional(readOnly = true)
		«ENDIF»
		public interface «entity.toRepositoryName» extends JpaRepository<«entity.toEntityName», «idType»>, QuerydslPredicateExecutor<«entity.toEntityName»> {
			«entity.generateDeleteInBulk»
			«IF hasAutoComplete»
			
			// WARNING: supports only where clause with like for STRING fields. For relationships entities will get the first string autocomplete key field name.
			@Query("«entity.generateAutoCompleteSQL(autoCompleteSlots.filter[it.isAutoCompleteResult], autoCompleteSlots.filter[it.isAutoCompleteKey])»")
			Collection<«entity.toAutoCompleteName»> autoComplete(@Param("query") String query);
			«ENDIF»
			«IF entity.hasListFilterMany»
			«entity.slots.filter[it.isListFilterManyEntity].map[generateListFilterAutoComplete].join»
			«ENDIF»
			«IF !findBySlots.empty»
			
			// Begin generated findBy
			«findBy»
			// End generated findBy
			«ENDIF»
		}
		'''
	}
	
	def CharSequence generateDeleteInBulk(Entity entity) {
		val alias = entity.toEntityAcronymName
		
		'''
		
		@Transactional
		@Modifying
		@Query("delete from «entity.toEntityName» «alias» where «alias».id in ?1")
		«entity.buildEntityDeleteInBulkMethdName»;
		
		'''
	}
	
	def CharSequence generateRepositoryFindByForEntity(Slot slot) {
		val findByList = slot.repositoryFindBy;
		'''
		
		«findByList.map[
			var code = ''//it.generateRepositoryFindByMethod(false)
			/*if (!it.hasCustom) {
				code += ';'
			}*/
			
			val signature = '''«it.buildFindByMethodReturn(false)» «it.buildFindByMethodName(true)»(«it.buildFindByMethodParams(false)»);'''
			code += signature
			// Gera o comando delete
			if (it.isDeleteBy) {
				var query = it.query
				
				val isNone = 'none' == query
				val isAuto = 'auto' == query
				
				val ownerEntity = slot.ownerEntity
				
				if (!isNone) {
					ownerEntity.addImport('import org.springframework.data.jpa.repository.Query;')
					ownerEntity.addImport('import org.springframework.data.jpa.repository.Modifying;')
				}
				
				if (isAuto) {
					val entityName = ownerEntity.toEntityName
					val alias = entityName.substring(0, 1).toLowerCase
					var field = slot.fieldName
					if (slot.isEntity) {
						field += '.' + slot.asEntity.id.fieldName
					}
					
					query = '''delete from «entityName» «alias» where «alias».«field» = ?1'''
				} // auto
				
				if ('none' != query) {
					code = '@Modifying' + '\r\n' +
					'@Query("' + query + '")' + '\r\n' + 
					code + '\r\n'
				}
				
				code = '\r\n' + '@Transactional' + '\r\n' + code
			} // if (it.isDeleteBy)
			
			code
		].join('\r\n')»
		'''
	}
	
	/*def CharSequence generateRepositoryFindByForEntity(Slot slot) {
		val findByList = slot.repositoryFindBy;
		'''
		
		«findByList.map[
			var code = it.generateRepositoryFindByMethod(true, false)
			if (!it.hasCustom) {
				code += ';'
			}
			
			if (it.isDeleteBy) {
				var query = it.query
				if ('auto' == query) {
					query = 'delete from '
				}
			}
			
			code
		].join('\r\n')»
		'''
	}*/
	
	def CharSequence generateListFilterAutoComplete(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		val slots = #[slot]
		
		'''
		
		// WARNING: supports only where clause with like for STRING fields. For relationships entities will get the first string autocomplete key field name.
		@Query("«slot.ownerEntity.generateAutoCompleteSQL(slots, slots)»")
		Collection<«autoComplateName.toFirstUpper»> «autoComplateName»(@Param("query") String query);
		'''
	}
	
	def String generateAutoCompleteSQL(Entity entity, Iterable<Slot> slotResultFields, Iterable<Slot> slotKeyFields) {
		
		//val sortSlots = entity.slots.filter[it.hasAutoComplete && it.autoComplete.hasSort]
		val sortSlots = slotResultFields.filter[it.hasAutoComplete && it.autoComplete.hasSort]
		
		val alias = "ac"
		val sql = new StringBuilder("select distinct ")
		val resultFields = slotResultFields.map[it | alias + "." + it.name.toFirstLower + " as " + it.name.toFirstLower].join(", ")
		sql.append(resultFields)
		sql.append(" from ").append(entity.toEntityName).append(" ").append(alias)
		sql.append(" where ")  // do not support where in fields that is not STRING yeat
		val keyFields = slotKeyFields.filter[it.isString || it.isEntity].map[it | // it.name.toFirstLower
			val query = if (it.hasUnassent) 'unaccent(:query)' else ':query'
			val beginUpper = if (it.hasUnassent) 'upper(unaccent(' else 'upper('
			val endUpper = if (it.hasUnassent) '))' else ')'
			"( " + beginUpper + alias + "." + it.resolveAutocompleteFieldName + endUpper + " like upper(concat('%', " + query + ", '%')) )"
		].join(" or ")
		sql.append(keyFields)
		
		// Sort
		if (!sortSlots.isEmpty) {
			val orderBy = ' order by ' + sortSlots.map[alias + '.' + it.fieldName + ' ' + it.autoComplete.sort.order].join(', ')
			sql.append(orderBy)
		}
		else {
			sql.append(" order by 1 asc")
		}
		sql.toString
	}
	
}