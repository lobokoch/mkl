package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.Slot

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
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val autoCompleteSlots = entity.slots.filter[it.hasAutoComplete]
		val hasAutoComplete = !autoCompleteSlots.isEmpty
		
		'''
		package «entity.package»;
		
		import org.springframework.data.jpa.repository.JpaRepository;
		import org.springframework.data.querydsl.QuerydslPredicateExecutor;
		«IF hasAutoComplete»
		import java.util.Collection;
		import org.springframework.data.repository.query.Param;
		import org.springframework.data.jpa.repository.Query;
		«ENDIF»
		«IF entity.isBaseRepository»
		import org.springframework.data.repository.NoRepositoryBean;
		
		@NoRepositoryBean
		«ELSE»
		
		«ENDIF»
		public interface «entity.toRepositoryName» extends JpaRepository<«entity.toEntityName», «idType»>, QuerydslPredicateExecutor<«entity.toEntityName»> {
			«IF hasAutoComplete»
			
			@Query("«entity.generateAutoCompleteSQL(autoCompleteSlots.filter[it.isAutoCompleteResult], autoCompleteSlots.filter[it.isAutoCompleteKey])»")
			Collection<«entity.toAutoCompleteName»> autoComplete(@Param("query") String query);
			«ENDIF»
			«IF entity.hasListFilterMany»
			«entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoComplete].join»
			«ENDIF»
			
		}
		'''
	}
	
	def CharSequence generateListFilterAutoComplete(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		val slots = #[slot]
		
		'''
		
		@Query("«slot.ownerEntity.generateAutoCompleteSQL(slots, slots)»")
		Collection<«autoComplateName.toFirstUpper»> «autoComplateName»(@Param("query") String query);
		'''
	}
	
	def String generateAutoCompleteSQL(Entity entity, Iterable<Slot> slotResultFields, Iterable<Slot> slotKeyFields) {
		val alias = "ac"
		val sql = new StringBuilder("select distinct ")
		val resultFields = slotResultFields.map[it | alias + "." + it.name.toFirstLower + " as " + it.name.toFirstLower].join(", ")
		sql.append(resultFields)
		sql.append(" from ").append(entity.toEntityName).append(" ").append(alias)
		sql.append(" where ")
		val keyFields = slotKeyFields.map[it | 
			"( upper(" + alias + "." + it.name.toFirstLower + ") like upper(concat('%', :query, '%')) )"
		].join(" or ")
		sql.append(keyFields)
		sql.append(" order by 1 asc")
		sql.toString
	}
	
	/*def String generateAutoCompleteSQL_(Entity entity, Iterable<Slot> slots) {
		val alias = "ac"
		val sql = new StringBuilder("select distinct ")
		val resultFields = slots.filter[it.isAutoCompleteResult].map[it | alias + "." + it.name.toFirstLower + " as " + it.name.toFirstLower].join(", ")
		sql.append(resultFields)
		sql.append(" from ").append(entity.toEntityName).append(" ").append(alias)
		sql.append(" where ")
		val keyFields = slots.filter[it.isAutoCompleteKey].map[it | 
			"( upper(" + alias + "." + it.name.toFirstLower + ") like upper(concat('%', :query, '%')) )"
		].join(" or ")
		sql.append(keyFields)
		sql.append(" order by 1 asc")
		sql.toString
	}*/
	
}