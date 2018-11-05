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
		entities.forEach[generateRepository]
	}
	
	def generateRepository(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toRepositoryName + '.java'
		generateFile(fileName, entity.generateEntityRepository)
	}
	
	def CharSequence generateEntityRepository(Entity entity) {
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val autoCompleteKeySlots = entity.slots.filter[it.isAutoCompleteResult]
		val hasAutoComplete = !autoCompleteKeySlots.isEmpty
		
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
			@Query("«entity.generateAutoCompleteSQL(autoCompleteKeySlots)»")
			Collection<«entity.toEntityAutoCompleteName»> autoComplete(@Param("token") String token);
			«ENDIF»
			
		}
		'''
	}
	
	def String generateAutoCompleteSQL(Entity entity, Iterable<Slot> slots) {
		val alias = "ac"
		val sql = new StringBuilder("select distinct ")
		val resultFields = slots.filter[it.isAutoCompleteResult].map[it | alias + "." + it.name.toFirstLower + " as " + it.name.toFirstLower].join(", ")
		sql.append(resultFields)
		sql.append(" from ").append(entity.toEntityName).append(" ").append(alias)
		sql.append(" where ")
		val keyFields = slots.filter[it.isAutoCompleteKey].map[it | 
			"( upper(" + alias + "." + it.name.toFirstLower + ") like upper(concat('%', :token, '%')) )"
		].join(" or ")
		sql.append(keyFields)
		sql.append(" order by 1 asc")
		sql.toString
	}
	
}