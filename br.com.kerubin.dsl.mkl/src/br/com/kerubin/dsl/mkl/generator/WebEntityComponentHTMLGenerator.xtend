package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.util.StringConcatenationExt
import br.com.kerubin.dsl.mkl.model.StringType
import br.com.kerubin.dsl.mkl.model.IntegerType
import br.com.kerubin.dsl.mkl.model.DoubleType
import br.com.kerubin.dsl.mkl.model.MoneyType
import br.com.kerubin.dsl.mkl.model.BooleanType
import br.com.kerubin.dsl.mkl.model.DateType
import br.com.kerubin.dsl.mkl.model.TimeType
import br.com.kerubin.dsl.mkl.model.DateTimeType
import br.com.kerubin.dsl.mkl.model.UUIDType
import br.com.kerubin.dsl.mkl.model.ByteType

class WebEntityComponentHTMLGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateComponent]
	}
	
	def generateComponent(Entity entity) {
		val path = entity.getWebEntityPath
		val entityFile = path + entity.toEntityWebComponentName + '.html'
		generateFile(entityFile, entity.doGenerateEntityComponentGenerator)
	}
	
	def CharSequence doGenerateEntityComponentGenerator(Entity entity) {
		'''
		<div class="container">
		
		  <form #form1="ngForm" (ngSubmit)="save(form1)">
		  	<div class="ui-g">
				«entity.generateEntityTitle»
				«entity.generateEntityFields»
				«IF entity.enableReplication»«entity.generateEntityReplication»«ENDIF»
				«entity.generateButtons»
			</div>
		  </form>
		  
		</div>
		'''
	}
	
	def CharSequence generateEntityReplication(Entity entity) {
		'''
		
		<!-- Begin Agrupador -->
		<div class="ui-g-12" *ngIf="«entity.fieldName».«entity.id.fieldName» != null" style="margin: 0 auto">
		      <div class="ui-g-12 ui-md-4 ui-fluid">
		        <label>Agrupador</label>
		        <input [(ngModel)]="«entity.fieldName».agrupador" minlength="3" pInputText type="text" name="agrupador" ngModel>
		      </div>
		
		      <div class="ui-g-12 ui-md-2 ui-fluid">
		        <label>Quantidade</label>
		        <p-spinner ngModel name="«entity.entityReplicationQuantity»" size="10" [(ngModel)]="«entity.entityReplicationQuantity»" [min]="1" [max]="100"></p-spinner>
		      </div>
		
		      <div class="ui-g-12 ui-md-2 ui-fluid centro-pai" >
		        <div class="ui-g-12 ui-md-2 centro-filho">
		          <button pButton (click)="«entity.entityReplicationMethod»" type="button" label="Replicar" class="ui-button-info"></button>
		        </div>
		      </div>
		</div>
		<!-- End Agrupador -->
		'''
	}
	
	def CharSequence generateButtons(Entity entity) {
		'''
		
		<div class="ui-g-12">
			<div class="ui-g-12 ui-md-4">
				<button [disabled]="!form1.valid" class="botao-margem-direita" pButton type="submit" label="Salvar"></button>
				<button pButton (click)="begin(form1)" type="button" label="Novo" class="botao-margem-direita ui-button-info"></button>
				<button pButton (click)="begin(form1)" type="button" label="Novo" class="botao-margem-direita ui-button-info"></button>
				<a routerLink="/«entity.toWebName»" pButton label="Pesquisar"></a>
			</div>
		</div>
		
		'''
	}
	
	def CharSequence generateEntityTitle(Entity entity) {
		'''
		<div>
			<h1>«entity.translationKey.transpationKeyFunc»</h1>
		</div>
		'''
	}
	
	def CharSequence generateEntityFields(Entity entity) {
		'''
		«entity.slots.map[generateField(entity)].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateField(Slot slot, Entity entity) {
		if (slot.isDTOFull) {
		}
		else if (slot.isDTOLookupResult) {
		}
		else if (slot.isEnum) { 
		}
		
		'''
		«IF slot.isToMany»
		slot.isToMany
		«ELSE»
		<div class="«slot.webClass»">
			<label>«slot.webLabel»</label>
			«slot.generateWebComponent»
		</div>
		«ENDIF»
		'''
	}
	
	def CharSequence generateWebComponent(Slot slot) {
		val builder = new StringConcatenationExt()
		builder.concat('<')
		slot.decoreWebComponent(builder)
		builder.concat(' />')
		
		slot.generateComponentMessages(builder)
		
		val result = builder.build
		result
	}
	
	def CharSequence generateComponentMessages(Slot slot, StringConcatenationExt builder) {
		if (!slot.optional) {
			builder.add('''<div class="invalid-message" *ngIf="«slot.fieldName».invalid && «slot.fieldName».dirty">Campo obrigatório.</div>''')
		}
	}
	
	def void decoreWebComponent(Slot slot, StringConcatenationExt builder) {
		slot.decorateWebComponentType(builder)
		slot.decorateWebComponentNgModel(builder)
		slot.decorateWebComponentName(builder)
		slot.decorateWebComponentRules(builder)
	}
	
	def void decorateWebComponentRules(Slot slot, StringConcatenationExt builder) {
		if (!slot.optional) {
			builder.concat(' required')
		}
		
		if (slot.UUID) {
			builder.concat(' readonly class="read-only"')
		}
	}
	
	def void decorateWebComponentName(Slot slot, StringConcatenationExt builder) {
			builder.concat(''' name="«slot.fieldName»"''')
	}
	
	def void decorateWebComponentNgModel(Slot slot, StringConcatenationExt builder) {
			builder.concat(''' ngModel [(ngModel)]="«slot.ownerEntity.fieldName».«slot.fieldName»"''')
	}
	
	def void decorateWebComponentType(Slot slot, StringConcatenationExt builder) {
		if (slot.isEntity) {
			val entity = slot.asEntity
			val fieldName = entity.slots.findFirst[it.autoCompleteResult]?.fieldName ?: entity.id.fieldName
			
			builder.concat('''p-autoComplete [forceSelection]="true" [suggestions]="«slot.webAutoCompleteSuggestions»" (completeMethod)="«slot.webAutoComplete»($event)" field="«fieldName»"''')
			return
		}
		else if (slot.isEnum){
			builder.concat('''p-dropdown [options]="«slot.webDropdownOptions»" placeholder="Selecione"''')
			return
		}
		
		// Is a basic type
		val basicType = slot.basicType
		
		if (basicType instanceof StringType) {
			val stringType = basicType as StringType
			// Must be a TextArea?
			if (stringType.length > 255) {
				builder.concat('textarea pInputTextarea rows="3"')			
			}
			else { // Input Text
				builder.concat('input type="text" pInputText')				
			}
		}
		else if (basicType instanceof IntegerType) {
			builder.concat('input type="text" pInputText')
		}
		else if (basicType instanceof DoubleType) {
			builder.concat('input type="text" pInputText')
		}
		else if (basicType instanceof MoneyType) {
			builder.concat('input currencyMask [options]="{prefix: \'\', thousands: \'.\', decimal: \',\', allowNegative: false}" placeholder="0,00"')
		}
		else if (basicType instanceof BooleanType) {
			builder.concat('p-inputSwitch')
		}
		else if (basicType instanceof DateType) {
			builder.concat('p-calendar dateFormat="dd/mm/yy"')
		}
		else if (basicType instanceof TimeType) {
			builder.concat('p-calendar dateFormat="hh:MM:ss"')
		}
		else if (basicType instanceof DateTimeType) {
			builder.concat('p-calendar dateFormat="dd/mm/yy hh:MM:ss"')
		}
		else if (basicType instanceof UUIDType) {
			builder.concat('input type="text" pInputText')
		}
		else if (basicType instanceof ByteType) {
			builder.concat('input type="text" pInputText')
		}
		
	}
	
	def CharSequence generateInputComponent(Slot slot) {
		val builder = new StringConcatenationExt()
		
		val result = builder.build
		result
	}
	
	
	
	def CharSequence generateGetters(Entity entity) {
		'''
		
		«entity.slots.map[generateGetter].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot) {
		
		'''
		«IF slot.isToMany»
		get «slot.name.toFirstUpper»(): «slot.toWebTypeDTO»[] {
		«ELSE»
		get «slot.name.toFirstUpper»(): «slot.toWebTypeDTO» {
		«ENDIF»
			return this.«slot.name.toFirstLower»;
		}
		'''
	}
	
	def CharSequence generateSetters(Entity entity) {
		'''
		
		«entity.slots.map[generateSetter].join('\r\n')»
		'''
	}
	
	def CharSequence generateSetter(Slot slot) {
		
		'''
		«IF slot.many && slot.isToMany»
		set «slot.name.toFirstUpper»(value: «slot.toWebTypeDTO»[]) {
		«ELSE»
		set «slot.name.toFirstUpper»(value: «slot.toWebTypeDTO») {
		«ENDIF»
			this.«slot.name.toFirstLower» = value;
		}
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