package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.BooleanType
import br.com.kerubin.dsl.mkl.model.ByteType
import br.com.kerubin.dsl.mkl.model.DateTimeType
import br.com.kerubin.dsl.mkl.model.DateType
import br.com.kerubin.dsl.mkl.model.DoubleType
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.IntegerType
import br.com.kerubin.dsl.mkl.model.MoneyType
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.StringType
import br.com.kerubin.dsl.mkl.model.TimeType
import br.com.kerubin.dsl.mkl.model.UUIDType
import br.com.kerubin.dsl.mkl.util.StringConcatenationExt

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*
import br.com.kerubin.dsl.mkl.model.Rule

class WebEntityCRUDComponentHTMLGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	val closedHTMLTags = #['p-', 'textarea']
	var webComponentType = ''
	
	boolean isOpenTagClosed
	 
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
		val path = entity.webEntityPath
		val entityFile = path + entity.toEntityWebCRUDComponentName + '.html'
		generateFile(entityFile, entity.doGenerateEntityComponentGenerator)
	}
	
	def CharSequence doGenerateEntityComponentGenerator(Entity entity) {
		val rules = entity.ruleMakeCopies
		
		'''
		<div class="container">
		
		  <form #form1="ngForm" (ngSubmit)="save(form1)">
		  	<div class="ui-g">
		  	
				«entity.generateEntityTitle»
				«entity.generateEntityFields»
				«IF !rules.empty»«entity.generateEntityCopies(rules.head)»«ENDIF»
				«entity.generateButtons»
			
			</div>
		  </form>
		  
		</div>
		'''
	}
	
	def CharSequence generateEntityCopies(Entity entity, Rule rule) {
		val makeCopies = rule.apply.makeCopiesExpression
		val title = makeCopies?.title ?: 'Gerar cópias'
		val actionName = rule.getRuleActionMakeCopiesName
		
		val actionButton = rule?.action?.actionButton
		val buttonToolTip = actionButton?.tooltip ?: 'Gerar cópias deste registro'
		val buttonLabel = actionButton?.label ?: 'Gerar cópias'
		val buttonIcon = actionButton?.icon ?: 'pi pi-clone'
		val min = makeCopies.minCopies
		val max = makeCopies.maxCopies
		
		'''
		 
		<!-- BEGIN make copies -->
		<!-- placeholder="Informe um identificador, exemplo: #luz_2019" -->
		<!-- <div class="invalid-message" *ngIf="copiesMustHaveGroup && !contaPagar.agrupador">Campo obrigatório para gerar cópias.</div> -->
		    <p-panel *ngIf="isEditing" class="ui-g-12" header="«title»"  [toggleable]="true" [collapsed]="true">
			    <div class="ui-g">
			    
				      <div class="ui-g-12 ui-fluid">
				        <div class="ui-g-12 ui-fluid ui-md-2">
				          <label for="numberOfCopies">Número de cópias</label>
				          <p-spinner size="30" name="numberOfCopies" [(ngModel)]="numberOfCopies" [min]="«min»" [max]="«max»"></p-spinner>
				        </div>
				
				        <div class="ui-g-12 ui-fluid ui-md-2">
				          <label for="copiesReferenceField" style="display: block">Campo de referência</label>
				          <p-dropdown optionLabel="label" name="copiesReferenceField" #copiesReferenceField="ngModel" [options]="copiesReferenceFieldOptions" ngModel [(ngModel)]="copiesReferenceFieldSelected" placeholder="Selecione"></p-dropdown>
				        </div>
				
				        <div class="ui-g-12 ui-md-2 ui-fluid">
				          <label for="copiesReferenceFieldInterval" style="display: block">Intervalo (dias)</label>
				          <p-spinner size="30" name="copiesReferenceFieldInterval" [(ngModel)]="copiesReferenceFieldInterval" [min]="1" [max]="1000"></p-spinner>
				        </div>
				
				        <div class="ui-g-12 ui-md-2 ui-fluid">
				          <span style="display: block">&nbsp;</span>
				          <button pButton (click)="«actionName»()" type="button" pTooltip="«buttonToolTip»" tooltipPosition="top" icon="«buttonIcon»" label="«buttonLabel»" class="ui-button-info"></button>
				        </div>
				      </div>
				      
			    </div>
		    
		    </p-panel>
		    <!-- END make copies -->
		'''
	}
	
	def CharSequence generateButtons(Entity entity) {
		'''
		
		<div class="ui-g-12">
			<div class="ui-g-12 ui-md-2 ui-fluid">
				<button [disabled]="!form1.valid" class="botao-margem-direita" pButton type="submit" label="Salvar"></button>
			</div>
			<div class="ui-g-12 ui-md-2 ui-fluid">
				<button pButton (click)="begin(form1)" type="button" label="Novo"></button>
			</div>
			<div class="ui-g-12 ui-md-2 ui-fluid">
				<a routerLink="/«entity.toWebName»" pButton label="Pesquisar"></a>
			</div>
		</div>
		
		'''
	}
	
	def CharSequence generateEntityTitle(Entity entity) {
		'''
		<div class="ui-g-12">
			<h1>«entity.translationKey.translationKeyFunc»</h1>
		</div>
		'''
	}
	
	def CharSequence generateEntityFields(Entity entity) {
		'''
		«entity.slots.filter[!mapped].map[generateField(entity)].join('\r\n')»
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
			<label «IF slot.isBoolean»style="display: block" «ENDIF»for="«slot.fieldName»"«IF slot.isHiddenSlot» class="hidden"«ENDIF»>«slot.webLabel»</label>
			«slot.generateWebComponent»
		</div>
		«ENDIF»
		'''
	}
	
	def CharSequence generateWebComponent(Slot slot) {
		webComponentType = '';
		val builder = new StringConcatenationExt()
		builder.concat('<')
		isOpenTagClosed = false
		slot.decoreWebComponent(builder)
		if (! isOpenTagClosed) {
			builder.concat('>')			
		}
		
		// It must close the HTML tag?
		if (closedHTMLTags.exists[webComponentType.startsWith(it)]) {
			builder.concat('</').concat(webComponentType).concat('>')			
		}
		
		slot.generateComponentMessages(builder)
		
		val result = builder.build
		result
	}
	
	def CharSequence generateComponentMessages(Slot slot, StringConcatenationExt builder) {
		if (!slot.UUID && !slot.optional) {
			builder.add('''<div class="invalid-message" *ngIf="«slot.fieldName».invalid && «slot.fieldName».dirty">Campo obrigatório.</div>''')
		}
	}
	
	def void decoreWebComponent(Slot slot, StringConcatenationExt builder) {
		slot.decorateWebComponentType(builder)
		slot.decorateWebComponentNgModel(builder)
		slot.decorateWebComponentName(builder)
		slot.decorateWebComponentRules(builder)
		
		// Tem que ser por último, porque fecha a tag.
		slot.decorateWebComponentAutoCompleteTemplate(builder)
	}
	
	def void decorateWebComponentRules(Slot slot, StringConcatenationExt builder) {
		if (!slot.UUID && !slot.optional) {
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
			builder.concat(''' #«slot.fieldName»="ngModel" ngModel [(ngModel)]="«slot.ownerEntity.fieldName».«slot.fieldName»"''')
	}
	
	def void decorateWebComponentAutoCompleteTemplate(Slot slot, StringConcatenationExt builder) {
		if (slot.isEntity) {
			val entity = slot.asEntity
			var resultSlots = entity.slots.filter[it.autoCompleteResult && it !== entity.id]
			if (resultSlots.isEmpty) {
				resultSlots = entity.slots.filter[it.autoCompleteResult]
			}
			if (!resultSlots.isEmpty) {
				builder.concat('>')
				isOpenTagClosed = true
				builder.addIndent('''
					<ng-template let-«slot.fieldName» pTemplate="item">
						«««<div class="ui-helper-clearfix">«resultSlots.map['''{{ «slot.fieldName».«it.fieldName» }}'''].join(' - ')»</div>
						<div class="ui-helper-clearfix">{{ «slot.webAutoCompleteFieldConverter»(«slot.fieldName») }}</div>
					</ng-template>
				''')
			}
			
		}
	}
	
	def void decorateWebComponentType(Slot slot, StringConcatenationExt builder) {
		if (slot.isEntity) {
			// Pega como resultado o primeiro campo de resultado que não seja o id da entidade, caso não tenha nenhum, ai traz o id da entidade como campo de resultado.
			webComponentType = 'p-autoComplete'
			builder
			.concat('''«webComponentType» placeholder="Digite para pesquisar..." [dropdown]="true" [forceSelection]="true"''')
			.concat(''' [suggestions]="«slot.webAutoCompleteSuggestions»"''')
			.concat(''' (completeMethod)="«slot.toAutoCompleteName»($event)"''')
			.concat(''' (onClear)="«slot.toAutoCompleteClearMethodName»($event)"''')
			.concat(''' [field]="«slot.webAutoCompleteFieldConverter»"''')
			return
		}
		else if (slot.isEnum){
			webComponentType = 'p-dropdown'
			builder.concat('''«webComponentType» [options]="«slot.webDropdownOptions»" optionLabel="label" placeholder="Selecione um item..."''')
			return
		}
		
		// Is a basic type
		val basicType = slot.basicType
		
		val inputType = if (slot.hiddenSlot) "hidden" else "text"
		
		if (basicType instanceof StringType) {
			val stringType = basicType as StringType
			// Must be a TextArea?
			if (stringType.length > 255) {
				webComponentType = 'textarea'
				builder.concat('''«webComponentType» pInputTextarea rows="3"''')			
			}
			else { // Input Text
				webComponentType = 'input'
				builder.concat('''«webComponentType» type="«inputType»" pInputText''')				
			}
		}
		else if (basicType instanceof IntegerType) {
			webComponentType = 'input'
			builder.concat('''«webComponentType» type="«inputType»" pInputText''')
		}
		else if (basicType instanceof DoubleType) {
			webComponentType = 'input'
			builder.concat('''«webComponentType» type="«inputType»" pInputText''')
		}
		else if (basicType instanceof MoneyType) {
			webComponentType = 'input'
			builder.concat('''«webComponentType» pInputText type="«inputType»" currencyMask [options]="{prefix: '', thousands: '.', decimal: ',', allowNegative: false}" placeholder="0,00"''')
		}
		else if (basicType instanceof BooleanType) {
			webComponentType = 'p-inputSwitch'
			builder.concat(webComponentType)
		}
		else if (basicType instanceof DateType) {
			webComponentType = 'p-calendar'
			builder.concat('''«webComponentType» dateFormat="dd/mm/yy"''')
		}
		else if (basicType instanceof TimeType) {
			webComponentType = 'p-calendar'
			builder.concat('''«webComponentType» dateFormat="hh:MM:ss"''')
		}
		else if (basicType instanceof DateTimeType) {
			webComponentType = 'p-calendar'
			builder.concat('''«webComponentType» dateFormat="dd/mm/yy hh:MM:ss"''')
		}
		else if (basicType instanceof UUIDType) {
			webComponentType = 'input'
			builder.concat('''«webComponentType» type="«inputType»" pInputText''')
		}
		else if (basicType instanceof ByteType) {
			webComponentType = 'input'
			builder.concat('''«webComponentType» type="«inputType»" pInputText''')
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