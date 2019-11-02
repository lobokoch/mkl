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
		
		if (hasAutoComplete) {
			entity.addImport('import java.util.Collection;')
		}
		
		
		'''
		package �entity.package�;
		
		import org.springframework.data.jpa.repository.JpaRepository;
		import org.springframework.data.querydsl.QuerydslPredicateExecutor;
		�entity.imports.map[it].join('\r\n')�
		�IF hasAutoComplete�
		import org.springframework.data.repository.query.Param;
		import org.springframework.data.jpa.repository.Query;
		�ENDIF�
		�IF entity.isBaseRepository�
		import org.springframework.data.repository.NoRepositoryBean;
		
		@NoRepositoryBean
		�ELSE�
		
		�ENDIF�
		public interface �entity.toRepositoryName� extends JpaRepository<�entity.toEntityName�, �idType�>, QuerydslPredicateExecutor<�entity.toEntityName�> {
			�IF hasAutoComplete�
			
			// WARNING: supports only where clause with like for STRING fields. For relationships entities will get the first string autocomplete key field name.
			@Query("�entity.generateAutoCompleteSQL(autoCompleteSlots.filter[it.isAutoCompleteResult], autoCompleteSlots.filter[it.isAutoCompleteKey])�")
			Collection<�entity.toAutoCompleteName�> autoComplete(@Param("query") String query);
			�ENDIF�
			�IF entity.hasListFilterMany�
			�entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoComplete].join�
			�ENDIF�
			�IF !findBySlots.empty�
			
			// Begin generated findBy
			�findBy�
			// End generated findBy
			�ENDIF�
		}
		'''
	}
	
	def CharSequence generateRepositoryFindByForEntity(Slot slot) {
		val findByList = slot.repositoryFindBy;
		'''
		
		// findBy for field �slot.fieldName�
		�findByList.map[it.generateRepositoryFindByMethod(true, false) + ';'].join('\r\n')�
		'''
	}
	
	def CharSequence generateListFilterAutoComplete(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		val slots = #[slot]
		
		'''
		// WARNING: supports only where clause with like for STRING fields. For relationships entities will get the first string autocomplete key field name.
		@Query("�slot.ownerEntity.generateAutoCompleteSQL(slots, slots)�")
		Collection<�autoComplateName.toFirstUpper�> �autoComplateName�(@Param("query") String query);
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
			"( upper(" + alias + "." + it.resolveAutocompleteFieldName + ") like upper(concat('%', :query, '%')) )"
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